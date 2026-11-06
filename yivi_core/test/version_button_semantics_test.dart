import "package:flutter/semantics.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/client_preferences.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/screens/more/widgets/version_button.dart";
import "package:yivi_core/src/theme/theme.dart";

import "helpers/test_translation_loader.dart";

// Regression test for #727: the version button excluded its subtree from
// semantics, so a screen reader could neither read the app ID and version
// aloud nor reach the tap target that enables developer mode.

class _RecordingBridge extends IrmaBridge {
  final dispatched = <Event>[];

  @override
  void dispatch(Event event) => dispatched.add(event);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const developerModeTaps = 7;

  Future<IrmaRepository> repository(_RecordingBridge bridge) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    final repo = IrmaRepository(client: bridge, preferences: preferences);

    // The app starts with the preference the Go side reports; the version
    // button waits for it before it enables developer mode.
    repo.dispatch(
      ClientPreferencesEvent(
        clientPreferences: ClientPreferences(developerMode: false),
      ),
    );
    return repo;
  }

  Future<void> pumpVersionButton(
    WidgetTester tester, {
    required IrmaRepository repo,
    Locale locale = const Locale("en", "US"),
  }) async {
    PackageInfo.setMockInitialValues(
      appName: "Yivi",
      packageName: "app.yivi",
      version: "8.3.3",
      buildNumber: "42",
      buildSignature: "",
    );

    final widget = IrmaRepositoryProvider(
      repository: repo,
      child: IrmaTheme(
        builder: (_) => MaterialApp(
          localizationsDelegates: [
            FlutterI18nDelegate(
              translationLoader: TestTranslationLoader(
                basePath: "assets/locales",
                forcedLocale: locale,
              ),
            ),
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Scaffold(body: VersionButton()),
        ),
      ),
    );

    // FileTranslationLoader reads the locale JSON with real IO, which the test
    // framework's fake clock does not drive: without runAsync plus a real
    // delay, Localizations never rebuilds and the tree stays empty. Dutch
    // loads two files (nl.json plus the en.json fallback).
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
  }

  testWidgets("announces the app ID and version as one tappable node", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final repo = await repository(_RecordingBridge());
    addTearDown(repo.close);
    await pumpVersionButton(tester, repo: repo);

    expect(find.bySemanticsLabel(RegExp(r"App ID")), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r"Version 8\.3\.3")), findsOneWidget);

    // One merged node carries both texts and the tap action, so a screen
    // reader reads them together and can activate the developer mode trigger.
    final node = tester.getSemantics(find.byType(InkWell));
    expect(node.label, matches(RegExp(r"App ID[\s\S]*Version 8\.3\.3")));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    handle.dispose();
  });

  testWidgets("the semantics tap action enables developer mode", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final bridge = _RecordingBridge();
    final repo = await repository(bridge);
    addTearDown(repo.close);
    await pumpVersionButton(tester, repo: repo);

    // Drive the semantics action itself, not a pointer tap: this is the path a
    // screen reader takes.
    for (var i = 0; i < developerModeTaps; i++) {
      tester.semantics.tap(find.semantics.byLabel(RegExp(r"App ID")));
      await tester.pump();
    }

    // The seventh tap reads the current developer mode from a stream before
    // it enables it; that read completes on the real event loop.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    final enabled = bridge.dispatched.whereType<ClientPreferencesEvent>().map(
      (event) => event.clientPreferences.developerMode,
    );
    expect(enabled, [true]);

    handle.dispose();
  });
}

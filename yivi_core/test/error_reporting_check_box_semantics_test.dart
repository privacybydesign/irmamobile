import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/screens/enrollment/accept_terms/widgets/error_reporting_check_box.dart";
import "package:yivi_core/src/theme/theme.dart";

// Companion to terms_check_box_semantics_test.dart (#638): the error reporting
// checkbox has the same shape — its label lives in a sibling rich-text widget,
// so without a merged label a screen reader announces only role and state.

class _RecordingBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const englishLabel =
      "Optional: Share error messages and app status with Yivi";

  Future<IrmaRepository> repository() async {
    SharedPreferences.setMockInitialValues({});
    return IrmaRepository(
      client: _RecordingBridge(),
      preferences: await IrmaPreferences.fromInstance(
        mostRecentTermsUrlNl: "",
        mostRecentTermsUrlEn: "",
      ),
    );
  }

  Future<void> pumpCheckBox(
    WidgetTester tester, {
    required IrmaRepository repo,
    Locale locale = const Locale("en", "US"),
  }) async {
    final widget = IrmaRepositoryProvider(
      repository: repo,
      child: IrmaTheme(
        builder: (_) => MaterialApp(
          localizationsDelegates: [
            FlutterI18nDelegate(
              translationLoader: FileTranslationLoader(
                basePath: "assets/locales",
                forcedLocale: locale,
              ),
            ),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: ErrorReportingCheckBox()),
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

  final checkbox = find.byKey(const Key("error_reporting_checkbox"));

  testWidgets("announces its label, checkbox role and unchecked state", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final repo = await repository();
    addTearDown(repo.close);
    await pumpCheckBox(tester, repo: repo);

    expect(
      tester.getSemantics(checkbox),
      matchesSemantics(
        // The visible label is three styled spans; the label joins them in
        // reading order so the spoken sentence matches the written one.
        label: englishLabel,
        hasCheckedState: true,
        isChecked: false,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );

    handle.dispose();
  });

  testWidgets("announces the checked state once error reporting is on", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final repo = await repository();
    addTearDown(repo.close);
    await repo.preferences.setReportErrors(true);
    await pumpCheckBox(tester, repo: repo);

    expect(
      tester.getSemantics(checkbox),
      matchesSemantics(
        label: englishLabel,
        hasCheckedState: true,
        isChecked: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );

    handle.dispose();
  });

  testWidgets("label is localized", (tester) async {
    final handle = tester.ensureSemantics();
    final repo = await repository();
    addTearDown(repo.close);
    await pumpCheckBox(tester, repo: repo, locale: const Locale("nl", "NL"));

    expect(
      tester.getSemantics(checkbox).label,
      "Optioneel: Foutmeldingen en app status delen met Yivi",
    );

    handle.dispose();
  });

  testWidgets("the semantics tap action toggles error reporting", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final repo = await repository();
    addTearDown(repo.close);
    await pumpCheckBox(tester, repo: repo);

    // Drive the semantics action itself, not a pointer tap: this is the path a
    // screen reader takes, and it goes through the merged node the label lives
    // on rather than the Checkbox's own hit box.
    tester.semantics.tap(find.semantics.byLabel(englishLabel));
    await tester.pumpAndSettle();

    expect(await repo.preferences.getReportErrors().first, isTrue);

    handle.dispose();
  });

  testWidgets("the info link stays reachable next to the checkbox", (
    tester,
  ) async {
    final repo = await repository();
    addTearDown(repo.close);
    await pumpCheckBox(tester, repo: repo);

    // The rich text is not merged into the checkbox, so the span that opens the
    // info sheet is still rendered and tappable on its own.
    expect(
      find.textContaining("Share error messages and app status"),
      findsOneWidget,
    );
  });
}

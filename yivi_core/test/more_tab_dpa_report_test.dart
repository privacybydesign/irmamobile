import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/screens/more/more_tab.dart";
import "package:yivi_core/src/theme/theme.dart";

import "helpers/test_translation_loader.dart";

// FSR_DPA_REPORT (#800): the More tab links to the page where a user can
// report to the Dutch Data Protection Authority.

class _IgnoringBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}
}

class _RecordingRepository extends IrmaRepository {
  final openedUrls = <String>[];

  _RecordingRepository({required super.client, required super.preferences});

  @override
  Future<void> openURL(String url) async => openedUrls.add(url);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_RecordingRepository> repository() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    return _RecordingRepository(
      client: _IgnoringBridge(),
      preferences: preferences,
    );
  }

  Future<void> pumpMoreTab(
    WidgetTester tester, {
    required IrmaRepository repo,
    required Locale locale,
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
          home: MoreTab(onChangeTab: (_) {}),
        ),
      ),
    );

    // The locale JSON loads with real IO, which the fake clock does not drive.
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
  }

  const cases = [
    (
      locale: Locale("en", "US"),
      label: "Report to the Data Protection Authority",
      url:
          "https://autoriteitpersoonsgegevens.nl/en/submitting-a-tip-off-or-a-complaint-to-the-ap",
    ),
    (
      locale: Locale("nl", "NL"),
      label: "Melden bij de Autoriteit Persoonsgegevens",
      url:
          "https://autoriteitpersoonsgegevens.nl/een-tip-of-klacht-indienen-bij-de-ap",
    ),
    (
      locale: Locale("de", "DE"),
      label: "Bei der Datenschutzbehörde melden",
      url:
          "https://autoriteitpersoonsgegevens.nl/en/submitting-a-tip-off-or-a-complaint-to-the-ap",
    ),
  ];

  for (final c in cases) {
    testWidgets("opens the AP complaint page in ${c.locale.languageCode}", (
      tester,
    ) async {
      final repo = await repository();
      addTearDown(repo.close);
      await pumpMoreTab(tester, repo: repo, locale: c.locale);

      final tile = find.text(c.label);
      await tester.scrollUntilVisible(tile, 100);
      await tester.tap(tile);
      await tester.pump();

      expect(repo.openedUrls, [c.url]);
    });
  }
}

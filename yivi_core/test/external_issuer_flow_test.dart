import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/session_state_provider.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/theme/theme.dart";

import "support/pump_translated.dart";

const _websiteCredential = "pbdf.gemeente.personalData";
const _issueUrl = "https://gemeente.example/start";
const _sessionId = 1;

class _RecordingBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}
}

TrustedParty _issuer() => TrustedParty(
  id: "gemeente",
  name: "Gemeente Voorbeeld",
  url: null,
  parent: null,
  verified: true,
);

class _Env {
  final IrmaPreferences prefs;
  final IrmaRepository repo;

  _Env(this.prefs, this.repo);

  List<dynamic> get overrides => [
    preferencesProvider.overrideWithValue(prefs),
    irmaRepositoryProvider.overrideWithValue(repo),
  ];
}

Future<_Env> _env() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await IrmaPreferences.fromInstance(
    mostRecentTermsUrlNl: "",
    mostRecentTermsUrlEn: "",
  );
  await prefs.clearAll();
  final repo = IrmaRepository(client: _RecordingBridge(), preferences: prefs);
  addTearDown(repo.close);
  return _Env(prefs, repo);
}

Future<void> _pumpApp(
  WidgetTester tester,
  _Env env,
  Widget home, {
  List<dynamic> overrides = const [],
}) async {
  final app = ProviderScope(
    overrides: [...env.overrides, ...overrides].cast(),
    child: IrmaTheme(
      builder: (_) => MaterialApp(
        localizationsDelegates: [
          FlutterI18nDelegate(
            translationLoader: FileTranslationLoader(
              basePath: "assets/locales",
              forcedLocale: const Locale("en", "US"),
            ),
          ),
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: home,
      ),
    ),
  );

  await pumpTranslated(tester, app);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("IssuancePermission", () {
    Future<void> pump(WidgetTester tester, {String? returnedFromIssuer}) async {
      final env = (await tester.runAsync(() => _env()))!;
      await _pumpApp(
        tester,
        env,
        IssuancePermission(
          issuedCredentials: const [],
          returnedFromIssuer: returnedFromIssuer,
        ),
      );
    }

    testWidgets("welcomes the user back from the issuer's website", (
      tester,
    ) async {
      await pump(tester, returnedFromIssuer: "Gemeente Voorbeeld");

      expect(
        find.text("Back from the website of Gemeente Voorbeeld"),
        findsOne,
      );
    });

    testWidgets("says nothing extra without a website issuer", (tester) async {
      await pump(tester);

      expect(find.textContaining("Back from"), findsNothing);
    });
  });

  group("SessionScreen issuance confirmation", () {
    const welcomeBack = "Back from the website of Gemeente Voorbeeld";

    SessionState offered() => SessionState(
      id: _sessionId,
      protocol: "irma",
      type: SessionType.issuance,
      status: SessionStatus.requestPermission,
      requestor: _issuer(),
      offeredCredentials: [
        Credential(
          credentialId: _websiteCredential,
          hash: "hash",
          name: "Persoonsgegevens",
          issuer: _issuer(),
          credentialInstanceIds: const {},
          batchInstanceCountsRemaining: const {},
          attributes: const [],
          revoked: false,
          revocationSupported: false,
          issueUrl: _issueUrl,
        ),
      ],
    );

    Future<_Env> pump(WidgetTester tester) async {
      final env = (await tester.runAsync(() => _env()))!;
      env.repo.markInAppLaunched([_websiteCredential]);
      await _pumpApp(
        tester,
        env,
        const SessionScreen(sessionId: _sessionId),
        overrides: [
          sessionStateProvider(
            _sessionId,
          ).overrideWith((ref) => Stream.value(offered())),
        ],
      );
      return env;
    }

    testWidgets("welcomes the user back after opening the website", (
      tester,
    ) async {
      await pump(tester);

      expect(find.text(welcomeBack), findsOne);
    });

    testWidgets("shows no welcome when the website was not opened from Yivi", (
      tester,
    ) async {
      final env = await pump(tester);

      env.repo.clearInAppLaunches();
      await tester.pumpAndSettle();

      expect(find.text(welcomeBack), findsNothing);
    });
  });
}

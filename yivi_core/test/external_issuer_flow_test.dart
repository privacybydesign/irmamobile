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
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/providers/external_issuer_provider.dart";
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

CredentialDescriptor _descriptor({
  String credentialId = _websiteCredential,
  String? issueUrl = _issueUrl,
}) => CredentialDescriptor(
  credentialId: credentialId,
  name: "Persoonsgegevens",
  issuer: _issuer(),
  category: null,
  attributes: const [],
  issueURL: issueUrl,
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

ExternalIssuerStatus _status(
  ProviderContainer container,
  CredentialDescriptor descriptor,
) => container.read(
  externalIssuerStatusProvider((
    credentialId: descriptor.credentialId,
    issueUrl: descriptor.issueURL,
  )),
);

Future<ProviderContainer> _container(_Env env) async {
  final container = ProviderContainer(overrides: [...env.overrides].cast());
  addTearDown(container.dispose);
  // Let the launched-credentials stream deliver its first value.
  container.listen(websiteLaunchedCredentialsProvider, (_, _) {});
  await Future<void>.delayed(Duration.zero);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("externalIssuerStatusProvider", () {
    test("is ready for a credential issued on a website", () async {
      final container = await _container(await _env());

      expect(_status(container, _descriptor()), ExternalIssuerStatus.ready);
    });

    test("is notExternal without an issue URL", () async {
      final container = await _container(await _env());

      expect(
        _status(container, _descriptor(issueUrl: null)),
        ExternalIssuerStatus.notExternal,
      );
      expect(
        _status(container, _descriptor(issueUrl: "")),
        ExternalIssuerStatus.notExternal,
      );
    });

    test("is notExternal for credentials with an embedded flow", () async {
      final container = await _container(await _env());

      for (final id in [
        "pbdf.pbdf.passport",
        "pbdf.sidn-pbdf.email",
        "pbdf-staging.sidn-pbdf.mobilenumber",
      ]) {
        expect(
          _status(container, _descriptor(credentialId: id)),
          ExternalIssuerStatus.notExternal,
          reason: id,
        );
      }
    });

    test(
      "is waiting once the website was opened, until it is cleared",
      () async {
        final env = await _env();
        final container = await _container(env);
        final descriptor = _descriptor();

        env.repo.markInAppLaunched([_websiteCredential]);
        await Future<void>.delayed(Duration.zero);
        expect(_status(container, descriptor), ExternalIssuerStatus.waiting);

        env.repo.clearInAppLaunches();
        await Future<void>.delayed(Duration.zero);
        expect(_status(container, descriptor), ExternalIssuerStatus.ready);
      },
    );

    test("only the credential whose website was opened is waiting", () async {
      final env = await _env();
      final container = await _container(env);

      env.repo.markInAppLaunched([_websiteCredential]);
      await Future<void>.delayed(Duration.zero);

      expect(
        _status(container, _descriptor(credentialId: "pbdf.other.credential")),
        ExternalIssuerStatus.ready,
      );
    });
  });

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

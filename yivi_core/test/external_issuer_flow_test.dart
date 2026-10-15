import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/feature_flags.dart";
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
import "package:yivi_core/src/screens/add_data/add_data_details_route.dart";
import "package:yivi_core/src/screens/add_data/external_issuer_heads_up_screen.dart";
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

Future<_Env> _env({required bool flagOn}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await IrmaPreferences.fromInstance(
    mostRecentTermsUrlNl: "",
    mostRecentTermsUrlEn: "",
  );
  await prefs.clearAll();
  await prefs.setFeatureFlag(FeatureFlag.externalIssuerFlow, flagOn);
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
  // Let the flag and launched-credentials streams deliver their first value.
  container.listen(externalIssuerFlowEnabledProvider, (_, _) {});
  container.listen(websiteLaunchedCredentialsProvider, (_, _) {});
  await Future<void>.delayed(Duration.zero);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("externalIssuerStatusProvider", () {
    test("is notExternal for every credential while the flag is off", () async {
      final container = await _container(await _env(flagOn: false));

      expect(
        _status(container, _descriptor()),
        ExternalIssuerStatus.notExternal,
      );
    });

    test("is ready for a credential issued on a website", () async {
      final container = await _container(await _env(flagOn: true));

      expect(_status(container, _descriptor()), ExternalIssuerStatus.ready);
    });

    test("is notExternal without an issue URL", () async {
      final container = await _container(await _env(flagOn: true));

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
      final container = await _container(await _env(flagOn: true));

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
        final env = await _env(flagOn: true);
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
      final env = await _env(flagOn: true);
      final container = await _container(env);

      env.repo.markInAppLaunched([_websiteCredential]);
      await Future<void>.delayed(Duration.zero);

      expect(
        _status(container, _descriptor(credentialId: "pbdf.other.credential")),
        ExternalIssuerStatus.ready,
      );
    });
  });

  group("ExternalIssuerHeadsUpScreen", () {
    Future<void> pump(
      WidgetTester tester, {
      VoidCallback? onOpenWebsite,
      VoidCallback? onBack,
    }) async {
      final env = (await tester.runAsync(() => _env(flagOn: true)))!;
      await _pumpApp(
        tester,
        env,
        ExternalIssuerHeadsUpScreen(
          credential: _descriptor(),
          onOpenWebsite: onOpenWebsite ?? () {},
          onBack: onBack ?? () {},
        ),
      );
    }

    testWidgets("names the credential, the website and the three steps", (
      tester,
    ) async {
      await pump(tester);

      expect(find.text("You're about to go to another website"), findsOne);
      expect(find.text("Persoonsgegevens"), findsOne);
      expect(find.text("gemeente.example"), findsOne);
      expect(find.text("Follow the steps on that website."), findsOne);
      expect(
        find.text("Yivi then opens by itself to add your Persoonsgegevens."),
        findsOne,
      );
      expect(find.text("You come back to this list."), findsOne);
    });

    testWidgets("falls back to the credential id for a nameless credential", (
      tester,
    ) async {
      final env = (await tester.runAsync(() => _env(flagOn: true)))!;
      await _pumpApp(
        tester,
        env,
        ExternalIssuerHeadsUpScreen(
          credential: CredentialDescriptor(
            credentialId: _websiteCredential,
            name: "",
            issuer: _issuer(),
            category: null,
            attributes: const [],
            issueURL: _issueUrl,
          ),
          onOpenWebsite: () {},
          onBack: () {},
        ),
      );

      expect(find.text(_websiteCredential), findsOne);
    });

    testWidgets("opens the website and goes back from its two buttons", (
      tester,
    ) async {
      var opened = 0;
      var wentBack = 0;
      await pump(
        tester,
        onOpenWebsite: () => opened++,
        onBack: () => wentBack++,
      );

      await tester.tap(find.text("Go to the website"));
      expect(opened, 1);
      expect(wentBack, 0);

      await tester.tap(find.text("Back to the list"));
      expect(wentBack, 1);
    });

    testWidgets("marks the website button with an external-link icon", (
      tester,
    ) async {
      await pump(tester);

      expect(
        find.descendant(
          of: find.byKey(const Key("bottom_bar_primary")),
          matching: find.byIcon(Icons.open_in_new),
        ),
        findsOne,
      );
    });
  });

  group("AddDataDetailsRoute", () {
    Future<void> pump(
      WidgetTester tester, {
      required bool flagOn,
      CredentialDescriptor? credential,
    }) async {
      final env = (await tester.runAsync(() => _env(flagOn: flagOn)))!;
      await _pumpApp(
        tester,
        env,
        AddDataDetailsRoute(
          credential: credential ?? _descriptor(),
          details: const Text("regular details"),
          onBack: () {},
          onOpenWebsite: () async {},
        ),
      );
    }

    testWidgets("keeps the regular details page while the flag is off", (
      tester,
    ) async {
      await pump(tester, flagOn: false);

      expect(find.text("regular details"), findsOne);
      expect(find.byType(ExternalIssuerHeadsUpScreen), findsNothing);
    });

    testWidgets("shows the heads-up screen for a website credential", (
      tester,
    ) async {
      await pump(tester, flagOn: true);

      expect(find.byType(ExternalIssuerHeadsUpScreen), findsOne);
      expect(find.text("regular details"), findsNothing);
    });

    testWidgets("keeps the regular details page for an embedded flow", (
      tester,
    ) async {
      await pump(
        tester,
        flagOn: true,
        credential: _descriptor(credentialId: "pbdf.sidn-pbdf.email"),
      );

      expect(find.text("regular details"), findsOne);
    });
  });

  group("IssuancePermission", () {
    Future<void> pump(WidgetTester tester, {String? returnedFromIssuer}) async {
      final env = (await tester.runAsync(() => _env(flagOn: true)))!;
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
        find.text("You're back from the website of Gemeente Voorbeeld"),
        findsOne,
      );
    });

    testWidgets("says nothing extra without a website issuer", (tester) async {
      await pump(tester);

      expect(find.textContaining("You're back from"), findsNothing);
    });
  });

  group("SessionScreen issuance confirmation", () {
    const welcomeBack = "You're back from the website of Gemeente Voorbeeld";

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

    Future<_Env> pump(WidgetTester tester, {required bool flagOn}) async {
      final env = (await tester.runAsync(() => _env(flagOn: flagOn)))!;
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
      await pump(tester, flagOn: true);

      expect(find.text(welcomeBack), findsOne);
    });

    testWidgets("shows no welcome while the flag is off", (tester) async {
      await pump(tester, flagOn: false);

      expect(find.text(welcomeBack), findsNothing);
    });

    testWidgets("shows no welcome when the website was not opened from Yivi", (
      tester,
    ) async {
      final env = await pump(tester, flagOn: true);

      env.repo.clearInAppLaunches();
      await tester.pumpAndSettle();

      expect(find.text(welcomeBack), findsNothing);
    });
  });
}

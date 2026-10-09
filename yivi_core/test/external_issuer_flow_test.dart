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
import "package:yivi_core/src/screens/session/widgets/disclosure_step_credential_card.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/screens/session/widgets/issue_during_disclosure_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "pump_and_load_locales.dart";

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

SessionState _sessionNeeding(CredentialDescriptor descriptor) => SessionState(
  id: _sessionId,
  protocol: "irma",
  type: SessionType.disclosure,
  status: SessionStatus.requestPermission,
  requestor: TrustedParty(
    id: "requestor",
    name: "Webshop",
    url: null,
    parent: null,
    verified: true,
  ),
  disclosurePlan: DisclosurePlan(
    issueDuringDisclosure: IssueDuringDisclosure(
      steps: [
        IssuanceStep(
          options: [
            IssuanceBundle(credentials: [descriptor]),
          ],
        ),
      ],
    ),
  ),
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

  await pumpAndLoadLocales(tester, app);
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

  group("DisclosureStepCredentialCard", () {
    const sourceLine = "Via the website of Gemeente Voorbeeld";
    const waitingStatus = "Not received yet";
    const waitingBody =
        "Still busy on the website of Gemeente Voorbeeld? Continue there. "
        "When you're done, Yivi opens by itself.";

    Future<_Env> pump(
      WidgetTester tester, {
      required bool flagOn,
      CredentialDescriptor? descriptor,
    }) async {
      final env = (await tester.runAsync(() => _env(flagOn: flagOn)))!;
      await _pumpApp(
        tester,
        env,
        Scaffold(
          body: DisclosureStepCredentialCard(
            descriptor: descriptor ?? _descriptor(),
            isCurrent: true,
          ),
        ),
      );
      return env;
    }

    testWidgets("looks as before while the flag is off", (tester) async {
      await pump(tester, flagOn: false);

      expect(find.text("Persoonsgegevens"), findsOne);
      expect(find.text(sourceLine), findsNothing);
      expect(find.byIcon(Icons.schedule), findsNothing);
    });

    testWidgets("says where the data comes from", (tester) async {
      await pump(tester, flagOn: true);

      expect(find.text(sourceLine), findsOne);
      expect(find.text(waitingStatus), findsNothing);
    });

    testWidgets("adds no source line for an embedded flow", (tester) async {
      await pump(
        tester,
        flagOn: true,
        descriptor: _descriptor(credentialId: "pbdf.sidn-pbdf.email"),
      );

      expect(find.text(sourceLine), findsNothing);
    });

    testWidgets("shows the waiting state once the website was opened", (
      tester,
    ) async {
      final env = await pump(tester, flagOn: true);

      env.repo.markInAppLaunched([_websiteCredential]);
      await tester.pumpAndSettle();

      expect(find.text(waitingStatus), findsOne);
      expect(find.text(waitingBody), findsOne);
      expect(find.byIcon(Icons.schedule), findsOne);
    });
  });

  group("IssueDuringDisclosureScreen primary button", () {
    Future<_Env> pump(WidgetTester tester, {required bool flagOn}) async {
      final env = (await tester.runAsync(() => _env(flagOn: flagOn)))!;
      await _pumpApp(
        tester,
        env,
        IssueDuringDisclosureScreen(
          sessionId: _sessionId,
          onDismiss: () {},
          onClose: () {},
        ),
        overrides: [
          sessionStateProvider(
            _sessionId,
          ).overrideWith((ref) => Stream.value(_sessionNeeding(_descriptor()))),
        ],
      );
      return env;
    }

    Finder primary(Finder matching) => find.descendant(
      of: find.byKey(const Key("bottom_bar_primary")),
      matching: matching,
    );

    testWidgets("is unchanged while the flag is off", (tester) async {
      await pump(tester, flagOn: false);

      expect(primary(find.text("Obtain data")), findsOne);
      expect(primary(find.byType(Icon)), findsNothing);
    });

    testWidgets("carries an external-link icon for a website credential", (
      tester,
    ) async {
      await pump(tester, flagOn: true);

      expect(primary(find.text("Obtain data")), findsOne);
      expect(primary(find.byIcon(Icons.open_in_new)), findsOne);
    });

    testWidgets("offers to open the website again when it is pending", (
      tester,
    ) async {
      final env = await pump(tester, flagOn: true);

      env.repo.markInAppLaunched([_websiteCredential]);
      await tester.pumpAndSettle();

      expect(primary(find.text("Open the website again")), findsOne);
      expect(primary(find.byIcon(Icons.open_in_new)), findsOne);
      expect(find.text("Not received yet"), findsOne);
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
}

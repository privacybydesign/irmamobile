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
import "package:yivi_core/src/providers/missing_data_flow_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/session_state_provider.dart";
import "package:yivi_core/src/screens/add_data/add_data_details_route.dart";
import "package:yivi_core/src/screens/add_data/external_issuer_heads_up_screen.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_step_credential_card.dart";
import "package:yivi_core/src/screens/session/widgets/external_issuer_checklist_row.dart";
import "package:yivi_core/src/screens/session/widgets/external_issuer_return_notice.dart";
import "package:yivi_core/src/screens/session/widgets/external_issuer_returned_screen.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/screens/session/widgets/issue_during_disclosure_screen.dart";
import "package:yivi_core/src/screens/session/widgets/missing_data_checklist_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/missing_data_band.dart";
import "support/pump_translated.dart";

const _websiteCredential = "pbdf.gemeente.personalData";
const _embeddedCredential = "pbdf.sidn-pbdf.email";
const _credentialName = "Persoonsgegevens";
const _issueUrl = "https://gemeente.example/start";
const _sessionId = 1;
const _sourceLine = "Via the website of Gemeente Voorbeeld";
const _fallbackText = "the regular row";
const _english = Locale("en", "US");
const _backButtonKey = Key("irma_app_bar_leading");

enum _Flag { on, off }

class _ActiveFlow extends MissingDataFlowNotifier {
  @override
  MissingDataFlow? build() => const MissingDataFlow(
    sessionId: _sessionId,
    credentialId: _websiteCredential,
  );
}

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
  String name = _credentialName,
}) => CredentialDescriptor(
  credentialId: credentialId,
  name: name,
  issuer: _issuer(),
  category: null,
  attributes: const [],
  issueURL: issueUrl,
);

SessionState _sessionNeeding(CredentialDescriptor descriptor) =>
    _sessionNeedingAll([descriptor]);

SessionState _sessionNeedingAll(List<CredentialDescriptor> descriptors) =>
    SessionState(
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
            for (final descriptor in descriptors)
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

Future<_Env> _env({required _Flag flag}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await IrmaPreferences.fromInstance(
    mostRecentTermsUrlNl: "",
    mostRecentTermsUrlEn: "",
  );
  await prefs.clearAll();
  await prefs.setFeatureFlag(FeatureFlag.externalIssuerFlow, flag == _Flag.on);
  final repo = IrmaRepository(client: _RecordingBridge(), preferences: prefs);
  addTearDown(repo.close);
  return _Env(prefs, repo);
}

Widget _app(
  _Env env,
  Widget home, {
  List<dynamic> overrides = const [],
  Locale locale = _english,
}) => ProviderScope(
  overrides: [...env.overrides, ...overrides].cast(),
  child: IrmaTheme(
    builder: (_) => MaterialApp(
      localizationsDelegates: [
        FlutterI18nDelegate(
          translationLoader: FileTranslationLoader(
            basePath: "assets/locales",
            forcedLocale: locale,
          ),
        ),
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: home,
    ),
  ),
);

Future<void> _pumpApp(
  WidgetTester tester,
  _Env env,
  Widget home, {
  List<dynamic> overrides = const [],
  Locale locale = _english,
}) async {
  await pumpTranslated(
    tester,
    _app(env, home, overrides: overrides, locale: locale),
  );
  await tester.pumpAndSettle();
}

Credential _offered() => Credential(
  credentialId: _websiteCredential,
  hash: "hash",
  name: _credentialName,
  issuer: _issuer(),
  credentialInstanceIds: const {},
  batchInstanceCountsRemaining: const {},
  attributes: [
    Attribute(
      claimPath: const ["firstnames"],
      displayName: "First names",
      value: AttributeValue(type: AttributeType.string, string: "Rosanne"),
    ),
    Attribute(
      claimPath: const ["familyname"],
      displayName: "Surname",
      value: AttributeValue(type: AttributeType.string, string: "de Vries"),
    ),
  ],
  revoked: false,
  revocationSupported: false,
  issueUrl: _issueUrl,
);

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
      final container = await _container(await _env(flag: _Flag.off));

      expect(
        _status(container, _descriptor()),
        ExternalIssuerStatus.notExternal,
      );
    });

    test("is ready for a credential issued on a website", () async {
      final container = await _container(await _env(flag: _Flag.on));

      expect(_status(container, _descriptor()), ExternalIssuerStatus.ready);
    });

    test("is notExternal without an issue URL", () async {
      final container = await _container(await _env(flag: _Flag.on));

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
      final container = await _container(await _env(flag: _Flag.on));

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
        final env = await _env(flag: _Flag.on);
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
      final env = await _env(flag: _Flag.on);
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
      String name = _credentialName,
      Locale locale = _english,
      List<dynamic> overrides = const [],
      VoidCallback? onOpenWebsite,
      VoidCallback? onBack,
    }) async {
      final env = (await tester.runAsync(() => _env(flag: _Flag.on)))!;
      await _pumpApp(
        tester,
        env,
        ExternalIssuerHeadsUpScreen(
          credential: _descriptor(name: name),
          onOpenWebsite: onOpenWebsite ?? () {},
          onBack: onBack ?? () {},
        ),
        locale: locale,
        overrides: overrides,
      );
    }

    testWidgets("names the credential, the website and the three steps", (
      tester,
    ) async {
      await pump(tester);

      expect(find.text("Obtain $_credentialName"), findsOne);
      expect(find.text("You're about to go to another website"), findsOne);
      expect(find.text(_credentialName), findsOne);
      expect(find.text("gemeente.example"), findsOne);
      expect(find.text("Follow the steps on that website."), findsOne);
      expect(
        find.text("Yivi then opens by itself to add your persoonsgegevens."),
        findsOne,
      );
      expect(find.text("You come back to this list."), findsOne);
    });

    testWidgets("keeps an acronym as it is in the sentence", (tester) async {
      await pump(tester, name: "BSN");

      expect(find.text("Yivi then opens by itself to add your BSN."), findsOne);
    });

    testWidgets("keeps a nouns capital in German", (tester) async {
      await pump(tester, locale: const Locale("de", "DE"));

      expect(
        find.text(
          "Danach öffnet sich Yivi von selbst, um Persoonsgegevens hinzuzufügen.",
        ),
        findsOne,
      );
    });

    testWidgets("falls back to the credential id for a nameless credential", (
      tester,
    ) async {
      final env = (await tester.runAsync(() => _env(flag: _Flag.on)))!;
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

      await tester.tap(find.byKey(_backButtonKey));
      expect(wentBack, 2);
    });

    testWidgets("labels the back arrow for the list it leads to", (
      tester,
    ) async {
      await pump(tester);

      expect(find.bySemanticsLabel("Back to the list"), findsWidgets);
    });

    testWidgets("marks the website button with an external-link icon", (
      tester,
    ) async {
      await pump(tester);

      expect(
        find.descendant(
          of: find.byKey(const Key("action_footer_primary")),
          matching: find.byIcon(Icons.open_in_new),
        ),
        findsOne,
      );
    });

    testWidgets("shows no band without a missing data flow", (tester) async {
      await pump(tester);

      expect(find.byType(MissingDataBand), findsNothing);
    });

    testWidgets("shows the band while collecting data for a request", (
      tester,
    ) async {
      await pump(
        tester,
        overrides: [
          missingDataFlowProvider.overrideWith(_ActiveFlow.new),
          missingDataBandProvider.overrideWithValue(null),
        ],
      );

      expect(find.byType(MissingDataBand), findsOne);
    });
  });

  group("AddDataDetailsRoute", () {
    Future<void> pump(
      WidgetTester tester, {
      required _Flag flag,
      CredentialDescriptor? credential,
    }) async {
      final env = (await tester.runAsync(() => _env(flag: flag)))!;
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
      await pump(tester, flag: _Flag.off);

      expect(find.text("regular details"), findsOne);
      expect(find.byType(ExternalIssuerHeadsUpScreen), findsNothing);
    });

    testWidgets("shows the heads-up screen for a website credential", (
      tester,
    ) async {
      await pump(tester, flag: _Flag.on);

      expect(find.byType(ExternalIssuerHeadsUpScreen), findsOne);
      expect(find.text("regular details"), findsNothing);
    });

    testWidgets("keeps the regular details page for an embedded flow", (
      tester,
    ) async {
      await pump(
        tester,
        flag: _Flag.on,
        credential: _descriptor(credentialId: _embeddedCredential),
      );

      expect(find.text("regular details"), findsOne);
    });
  });

  group("DisclosureStepCredentialCard", () {
    const waitingStatus = "Not received yet";
    const waitingBody =
        "Still busy on the website of Gemeente Voorbeeld? Continue there. "
        "When you're done, Yivi opens by itself.";

    Future<_Env> pump(
      WidgetTester tester, {
      required _Flag flag,
      CredentialDescriptor? descriptor,
    }) async {
      final env = (await tester.runAsync(() => _env(flag: flag)))!;
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
      await pump(tester, flag: _Flag.off);

      expect(find.text(_credentialName), findsOne);
      expect(find.text(_sourceLine), findsNothing);
      expect(find.text(waitingStatus), findsNothing);
    });

    testWidgets("says where the data comes from", (tester) async {
      await pump(tester, flag: _Flag.on);

      expect(find.text(_sourceLine), findsOne);
      expect(find.text(waitingStatus), findsNothing);
    });

    testWidgets("adds no source line for an embedded flow", (tester) async {
      await pump(
        tester,
        flag: _Flag.on,
        descriptor: _descriptor(credentialId: _embeddedCredential),
      );

      expect(find.text(_sourceLine), findsNothing);
    });

    testWidgets("shows the waiting state once the website was opened", (
      tester,
    ) async {
      final env = await pump(tester, flag: _Flag.on);

      env.repo.markInAppLaunched([_websiteCredential]);
      await tester.pumpAndSettle();

      expect(find.text(waitingStatus), findsOne);
      expect(find.text(waitingBody), findsOne);
      expect(find.text(_sourceLine), findsNothing);
      expect(find.byIcon(Icons.schedule), findsNothing);
    });
  });

  group("ExternalIssuerChecklistRow", () {
    Future<_Env> pump(
      WidgetTester tester, {
      required _Flag flag,
      CredentialDescriptor? descriptor,
      VoidCallback? onObtain,
    }) async {
      final env = (await tester.runAsync(() => _env(flag: flag)))!;
      await _pumpApp(
        tester,
        env,
        Scaffold(
          body: ExternalIssuerChecklistRow(
            credential: descriptor ?? _descriptor(),
            onObtain: onObtain ?? () {},
            fallback: const Text(_fallbackText),
          ),
        ),
      );
      return env;
    }

    testWidgets("builds the regular row while the flag is off", (tester) async {
      await pump(tester, flag: _Flag.off);

      expect(find.text(_fallbackText), findsOne);
      expect(find.text(_sourceLine), findsNothing);
    });

    testWidgets("builds the regular row for an embedded flow", (tester) async {
      await pump(
        tester,
        flag: _Flag.on,
        descriptor: _descriptor(credentialId: _embeddedCredential),
      );

      expect(find.text(_fallbackText), findsOne);
    });

    testWidgets("says where the data comes from and offers to get it", (
      tester,
    ) async {
      var obtained = 0;
      await pump(tester, flag: _Flag.on, onObtain: () => obtained++);

      expect(find.text(_fallbackText), findsNothing);
      expect(find.text(_credentialName), findsOne);
      expect(find.text(_sourceLine), findsOne);
      expect(find.byIcon(Icons.open_in_new), findsOne);

      await tester.tap(find.text("Obtain"));
      expect(obtained, 1);
    });

    testWidgets("names the credential and the website for screen readers", (
      tester,
    ) async {
      await pump(tester, flag: _Flag.on);

      expect(
        find.bySemanticsLabel("Obtain: Persoonsgegevens, opens a website"),
        findsOne,
      );
    });

    testWidgets("waits for the website once it was opened", (tester) async {
      var obtained = 0;
      final env = await pump(
        tester,
        flag: _Flag.on,
        onObtain: () => obtained++,
      );

      env.repo.markInAppLaunched([_websiteCredential]);
      await tester.pumpAndSettle();

      expect(find.text("Not received yet"), findsOne);
      expect(find.textContaining("Still busy on the website of"), findsOne);
      expect(find.text(_sourceLine), findsNothing);
      expect(find.text("Obtain"), findsNothing);

      await tester.tap(find.text("Open the website again"));
      expect(obtained, 1);
    });
  });

  group("MissingDataChecklistScreen", () {
    Future<void> pump(WidgetTester tester, {required _Flag flag}) async {
      final env = (await tester.runAsync(() => _env(flag: flag)))!;
      final session = _sessionNeedingAll([
        _descriptor(),
        _descriptor(credentialId: _embeddedCredential, name: "E-mailadres"),
      ]);
      await _pumpApp(
        tester,
        env,
        MissingDataChecklistScreen(sessionId: _sessionId, onDismiss: () {}),
        overrides: [
          sessionStateProvider(
            _sessionId,
          ).overrideWith((ref) => Stream.value(session)),
        ],
      );
    }

    testWidgets("marks the row of a website credential", (tester) async {
      await pump(tester, flag: _Flag.on);

      expect(find.text(_sourceLine), findsOne);
      expect(find.text("Not in your app yet"), findsOne);
    });

    testWidgets("leaves the rows as they were while the flag is off", (
      tester,
    ) async {
      await pump(tester, flag: _Flag.off);

      expect(find.text(_sourceLine), findsNothing);
      expect(find.text("Not in your app yet"), findsNWidgets(2));
    });
  });

  group("IssueDuringDisclosureScreen primary button", () {
    Future<_Env> pump(WidgetTester tester, {required _Flag flag}) async {
      final env = (await tester.runAsync(() => _env(flag: flag)))!;
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
      await pump(tester, flag: _Flag.off);

      expect(primary(find.text("Obtain data")), findsOne);
      expect(primary(find.byType(Icon)), findsNothing);
    });

    testWidgets("carries an external-link icon for a website credential", (
      tester,
    ) async {
      await pump(tester, flag: _Flag.on);

      expect(primary(find.text("Obtain data")), findsOne);
      expect(primary(find.byIcon(Icons.open_in_new)), findsOne);
    });

    testWidgets("offers to open the website again when it is pending", (
      tester,
    ) async {
      final env = await pump(tester, flag: _Flag.on);

      env.repo.markInAppLaunched([_websiteCredential]);
      await tester.pumpAndSettle();

      expect(primary(find.text("Open the website again")), findsOne);
      expect(primary(find.byIcon(Icons.open_in_new)), findsOne);
      expect(find.text("Not received yet"), findsOne);
    });
  });

  group("IssuancePermission", () {
    Future<void> pump(
      WidgetTester tester, {
      Credential? returnedFrom,
      VoidCallback? onGivePermission,
      VoidCallback? onDismiss,
    }) async {
      final env = (await tester.runAsync(() => _env(flag: _Flag.on)))!;
      await _pumpApp(
        tester,
        env,
        IssuancePermission(
          issuedCredentials: [_offered()],
          returnedFrom: returnedFrom,
          onGivePermission: onGivePermission ?? () {},
          onDismiss: onDismiss ?? () {},
        ),
      );
    }

    Finder notice() => find.descendant(
      of: find.byType(ExternalIssuerReturnNotice),
      matching: find.byType(FadeTransition),
    );

    double noticeOpacity(WidgetTester tester) =>
        tester.widget<FadeTransition>(notice()).opacity.value;

    testWidgets("looks as before without a website issuer", (tester) async {
      await pump(tester);

      expect(find.byType(ExternalIssuerReturnedScreen), findsNothing);
      expect(find.textContaining("You're back from"), findsNothing);
      expect(find.text("Add data"), findsWidgets);
    });

    testWidgets("titles the screen after the credential that was fetched", (
      tester,
    ) async {
      await pump(tester, returnedFrom: _offered());

      expect(find.text("Obtain $_credentialName"), findsOne);
      expect(find.byKey(_backButtonKey), findsNothing);
      expect(
        find.text("Do you want to add this data to your Yivi app?"),
        findsOne,
      );
    });

    testWidgets("names the issuer's website in the notice", (tester) async {
      await pump(tester, returnedFrom: _offered());

      expect(
        find.text("You're back from the website of Gemeente Voorbeeld"),
        findsOne,
      );
    });

    testWidgets("shows the credential with all its attributes", (tester) async {
      await pump(tester, returnedFrom: _offered());

      expect(find.text(_credentialName), findsWidgets);
      expect(find.text("Gemeente Voorbeeld"), findsOne);
      expect(find.text("First names"), findsOne);
      expect(find.text("Rosanne"), findsOne);
      expect(find.text("Surname"), findsOne);
      expect(find.text("de Vries"), findsOne);
    });

    testWidgets("adds the credential, or goes back to the list", (
      tester,
    ) async {
      var added = 0;
      var wentBack = 0;
      await pump(
        tester,
        returnedFrom: _offered(),
        onGivePermission: () => added++,
        onDismiss: () => wentBack++,
      );

      await tester.tap(find.text("Add"));
      expect(added, 1);
      expect(wentBack, 0);

      await tester.tap(find.text("Back to the list"));
      expect(wentBack, 1);
    });

    testWidgets("slides the notice in, holds it and fades it out", (
      tester,
    ) async {
      final env = (await tester.runAsync(() => _env(flag: _Flag.on)))!;
      await pumpTranslated(
        tester,
        _app(
          env,
          IssuancePermission(
            issuedCredentials: [_offered()],
            returnedFrom: _offered(),
          ),
        ),
      );

      expect(noticeOpacity(tester), 0);

      await tester.pump(const Duration(milliseconds: 700));
      expect(noticeOpacity(tester), 1);

      await tester.pump(const Duration(seconds: 2));
      expect(noticeOpacity(tester), 1);

      await tester.pump(const Duration(seconds: 2));
      expect(noticeOpacity(tester), 0);
    });

    testWidgets("keeps the notice in view while animations are off", (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pump(tester, returnedFrom: _offered());

      expect(noticeOpacity(tester), 1);

      await tester.pump(const Duration(seconds: 5));

      expect(noticeOpacity(tester), 1);
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
      offeredCredentials: [_offered()],
    );

    Future<_Env> pump(WidgetTester tester, {required _Flag flag}) async {
      final env = (await tester.runAsync(() => _env(flag: flag)))!;
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
      await pump(tester, flag: _Flag.on);

      expect(find.text(welcomeBack), findsOne);
    });

    testWidgets("shows no welcome while the flag is off", (tester) async {
      await pump(tester, flag: _Flag.off);

      expect(find.text(welcomeBack), findsNothing);
    });

    testWidgets("shows no welcome when the website was not opened from Yivi", (
      tester,
    ) async {
      final env = await pump(tester, flag: _Flag.on);

      env.repo.clearInAppLaunches();
      await tester.pumpAndSettle();

      expect(find.text(welcomeBack), findsNothing);
    });
  });
}

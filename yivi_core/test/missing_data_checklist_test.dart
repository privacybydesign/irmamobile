import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/missing_data_checklist.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/issue_during_disclosure_provider.dart";
import "package:yivi_core/src/providers/missing_data_flow_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/irma_card.dart";
import "package:yivi_core/src/widgets/yivi_themed_button.dart";

const _sessionId = 1;

TrustedParty _party(String name, {bool verified = true}) => TrustedParty(
  id: name,
  name: name,
  url: null,
  parent: null,
  verified: verified,
);

CredentialDescriptor _desc(String id, {String? issueURL = "https://issuer"}) =>
    CredentialDescriptor(
      credentialId: id,
      name: "Cred $id",
      issuer: _party("Issuer"),
      category: null,
      attributes: const [],
      issueURL: issueURL,
    );

IssuanceStep _step(List<List<CredentialDescriptor>> options) => IssuanceStep(
  options: [for (final o in options) IssuanceBundle(credentials: o)],
);

IssueDuringDisclosureState _wizard(
  List<IssuanceStep> steps, {
  Set<String> issued = const {},
  List<int>? selections,
}) => IssueDuringDisclosureState(
  steps: steps,
  selectedOptionPerStep: selections ?? List.filled(steps.length, 0),
  issuedCredentialIds: issued,
);

SelectableCredentialInstance _instance(String id) =>
    SelectableCredentialInstance(
      credentialId: id,
      hash: "hash-$id",
      name: "Cred $id",
      issuer: _party("Issuer"),
      format: CredentialFormat.idemix,
      attributes: const [],
      revoked: false,
      revocationSupported: false,
    );

SessionState _session({
  required List<IssuanceStep> steps,
  Set<String> issued = const {},
  bool withChoices = false,
  SessionType type = SessionType.disclosure,
  bool verified = true,
}) => SessionState(
  id: _sessionId,
  protocol: "irma",
  type: type,
  status: SessionStatus.requestPermission,
  requestor: _party("Test Verifier", verified: verified),
  disclosurePlan: DisclosurePlan(
    issueDuringDisclosure: IssueDuringDisclosure(
      steps: steps,
      issuedCredentialIds: {for (final id in issued) id: null},
    ),
    disclosureChoicesOverview: withChoices
        ? [
            for (final step in steps)
              DisclosurePickOne(
                optional: false,
                ownedOptions: [
                  DisclosureBundle(
                    credentials: [
                      for (final c in step.options.first.credentials)
                        _instance(c.credentialId),
                    ],
                  ),
                ],
              ),
          ]
        : null,
  ),
);

class _TestBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}

  void emit(Event event) => addEvent(event);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("MissingDataChecklist", () {
    final email = _desc("email");
    final phone = _desc("phone");

    test("counts the credentials of every step", () {
      final checklist = MissingDataChecklist.fromWizardState(
        _wizard([
          _step([
            [email],
          ]),
          _step([
            [phone],
          ]),
        ]),
      );

      expect(checklist.total, 2);
      expect(checklist.presentCount, 0);
      expect(checklist.missingCount, 2);
      expect(checklist.isComplete, isFalse);
    });

    test("marks issued credentials as present and moves next", () {
      final checklist = MissingDataChecklist.fromWizardState(
        _wizard(
          [
            _step([
              [email],
            ]),
            _step([
              [phone],
            ]),
          ],
          issued: {"email"},
        ),
      );

      expect(checklist.presentCount, 1);
      expect(checklist.next?.entry.credential.credentialId, "phone");
      expect(checklist.next?.step.index, 1);
    });

    test("is complete when every credential is issued", () {
      final checklist = MissingDataChecklist.fromWizardState(
        _wizard(
          [
            _step([
              [email],
            ]),
          ],
          issued: {"email"},
        ),
      );

      expect(checklist.isComplete, isTrue);
      expect(checklist.next, isNull);
    });

    test("next skips credentials that cannot be obtained in the app", () {
      final checklist = MissingDataChecklist.fromWizardState(
        _wizard([
          _step([
            [_desc("elsewhere", issueURL: null)],
          ]),
          _step([
            [phone],
          ]),
        ]),
      );

      expect(checklist.next?.entry.credential.credentialId, "phone");
    });

    test("a multi-credential bundle counts every credential", () {
      final checklist = MissingDataChecklist.fromWizardState(
        _wizard(
          [
            _step([
              [email, phone],
            ]),
          ],
          issued: {"email"},
        ),
      );

      expect(checklist.total, 2);
      expect(checklist.presentCount, 1);
      expect(checklist.steps.single.isPresent, isFalse);
    });

    test("a step with options is a choice until one option is obtained", () {
      final steps = [
        _step([
          [email],
          [phone],
        ]),
      ];

      final open = MissingDataChecklist.fromWizardState(_wizard(steps));
      expect(open.steps.single.isChoice, isTrue);
      expect(open.total, 1);

      final done = MissingDataChecklist.fromWizardState(
        _wizard(steps, issued: {"phone"}),
      );
      expect(done.steps.single.isChoice, isFalse);
      expect(done.steps.single.entries.single.credential.credentialId, "phone");
      expect(done.isComplete, isTrue);
    });

    test("follows the selected option while none is obtained", () {
      final checklist = MissingDataChecklist.fromWizardState(
        _wizard(
          [
            _step([
              [email],
              [phone],
            ]),
          ],
          selections: [1],
        ),
      );

      expect(checklist.steps.single.shownOptionIndex, 1);
      expect(
        checklist.steps.single.entries.single.credential.credentialId,
        "phone",
      );
    });

    test("ignores a selection outside the options", () {
      final checklist = MissingDataChecklist.fromWizardState(
        _wizard(
          [
            _step([
              [email],
            ]),
          ],
          selections: [5],
        ),
      );

      expect(checklist.steps.single.shownOptionIndex, 0);
    });
  });

  group("SessionScreen with FeatureFlag.missingDataChecklist", () {
    late _TestBridge bridge;
    late IrmaRepository repo;
    late IrmaPreferences prefs;
    late GoRouter router;
    late ProviderContainer container;

    Future<void> setUpScreen(
      WidgetTester tester, {
      required bool flagOn,
    }) async {
      bridge = _TestBridge();
      router = GoRouter(
        initialLocation: "/session",
        routes: [
          GoRoute(
            path: "/session",
            builder: (_, _) => const SessionScreen(sessionId: _sessionId),
          ),
          GoRoute(
            path: "/home/add_data/details",
            builder: (_, _) => const Scaffold(body: Text("details screen")),
          ),
        ],
      );

      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues({});
        prefs = await IrmaPreferences.fromInstance(
          mostRecentTermsUrlNl: "",
          mostRecentTermsUrlEn: "",
        );
        await prefs.clearAll();
        await prefs.setCompletedDisclosurePermissionIntro(true);
        await prefs.setFeatureFlag(FeatureFlag.missingDataChecklist, flagOn);
      });

      repo = IrmaRepository(client: bridge, preferences: prefs);
      addTearDown(repo.close);

      container = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          irmaRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await tester.runAsync(() async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: IrmaTheme(
              builder: (_) => MaterialApp.router(
                routerConfig: router,
                localizationsDelegates: [
                  FlutterI18nDelegate(
                    translationLoader: FileTranslationLoader(
                      basePath: "assets/locales",
                      forcedLocale: const Locale("nl"),
                    ),
                  ),
                  ...GlobalMaterialLocalizations.delegates,
                ],
              ),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pump();
    }

    Future<void> emit(WidgetTester tester, SessionState session) async {
      bridge.emit(SessionStateEvent(sessionState: session));
      await tester.pump();
      await tester.pump();
    }

    final email = _desc("email");
    final phone = _desc("phone");
    final twoSteps = [
      _step([
        [email],
      ]),
      _step([
        [phone],
      ]),
    ];

    testWidgets("lists the missing credentials, the first one ringed", (
      tester,
    ) async {
      await setUpScreen(tester, flagOn: true);
      await emit(tester, _session(steps: twoSteps));

      expect(find.text("Test Verifier vraagt om 2 gegevens"), findsOneWidget);
      expect(find.text("Bekende partij"), findsOneWidget);
      expect(find.text("0 van 2 klaar"), findsOneWidget);
      expect(find.text("Nog niet in je app"), findsNWidgets(2));
      expect(find.text("Ophalen"), findsNWidgets(2));

      final first = tester.widget<Container>(
        find.byKey(const Key("missing_data_row_email")),
      );
      final second = tester.widget<Container>(
        find.byKey(const Key("missing_data_row_phone")),
      );
      expect(first.foregroundDecoration, isNotNull);
      expect(second.foregroundDecoration, isNull);
    });

    testWidgets("keeps sharing disabled and says what is missing", (
      tester,
    ) async {
      await setUpScreen(tester, flagOn: true);
      await emit(tester, _session(steps: twoSteps));

      expect(find.text("Stap 1 van 2"), findsNothing);
      expect(find.text("Delen met Test Verifier"), findsOneWidget);
      expect(find.text("Haal eerst de 2 ontbrekende gegevens op"), findsOne);
      final share = tester.widget<YiviThemedButton>(
        find.byKey(const Key("missing_data_share_disabled")),
      );
      expect(share.onPressed, isNull);
    });

    testWidgets("uses the singular for a single missing credential", (
      tester,
    ) async {
      await setUpScreen(tester, flagOn: true);
      await emit(tester, _session(steps: [twoSteps.first]));

      expect(find.text("Test Verifier vraagt om 1 gegeven"), findsOneWidget);
      expect(find.text("Haal eerst het ontbrekende gegeven op"), findsOne);
    });

    testWidgets("flags an unknown requestor", (tester) async {
      await setUpScreen(tester, flagOn: true);
      await emit(tester, _session(steps: twoSteps, verified: false));

      expect(find.text("Onbekende partij"), findsOneWidget);
    });

    testWidgets("counts up, flashes the new row and moves the ring", (
      tester,
    ) async {
      await setUpScreen(tester, flagOn: true);
      await emit(tester, _session(steps: twoSteps));
      await emit(tester, _session(steps: twoSteps, issued: {"email"}));

      expect(find.text("1 van 2 klaar"), findsOneWidget);
      expect(find.text("Zojuist toegevoegd"), findsOneWidget);
      expect(find.text("Nog niet in je app"), findsOneWidget);
      expect(find.text("Ophalen"), findsOneWidget);

      final theme = IrmaThemeData();
      Color? rowColor() => tester
          .widget<IrmaCard>(
            find.descendant(
              of: find.byKey(const Key("missing_data_row_email")),
              matching: find.byType(IrmaCard),
            ),
          )
          .color;

      // Green right after it is added, white again once the flash is over.
      await tester.pump();
      expect(rowColor(), theme.successSurface);
      await tester.pump(const Duration(seconds: 2));
      expect(rowColor(), theme.light);

      final first = tester.widget<Container>(
        find.byKey(const Key("missing_data_row_email")),
      );
      final second = tester.widget<Container>(
        find.byKey(const Key("missing_data_row_phone")),
      );
      expect(first.foregroundDecoration, isNull);
      expect(second.foregroundDecoration, isNotNull);
    });

    testWidgets("shows no flash when animations are disabled", (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await setUpScreen(tester, flagOn: true);
      await emit(tester, _session(steps: twoSteps));
      await emit(tester, _session(steps: twoSteps, issued: {"email"}));
      await tester.pump();

      final color = tester
          .widget<IrmaCard>(
            find.descendant(
              of: find.byKey(const Key("missing_data_row_email")),
              matching: find.byType(IrmaCard),
            ),
          )
          .color;
      expect(color, IrmaThemeData().light);
      expect(find.text("Zojuist toegevoegd"), findsOneWidget);
    });

    testWidgets("obtaining starts the flow and clears it on return", (
      tester,
    ) async {
      await setUpScreen(tester, flagOn: true);
      await emit(tester, _session(steps: twoSteps));

      await tester.tap(find.text("Ophalen").last);
      await tester.pumpAndSettle();

      expect(find.text("details screen"), findsOneWidget);
      final flow = container.read(missingDataFlowProvider);
      expect(flow?.sessionId, _sessionId);
      expect(flow?.credentialId, "phone");

      router.pop();
      await tester.pumpAndSettle();

      expect(find.text("details screen"), findsNothing);
      expect(container.read(missingDataFlowProvider), isNull);
    });

    testWidgets("keeps the choice between options", (tester) async {
      await setUpScreen(tester, flagOn: true);
      await emit(
        tester,
        _session(
          steps: [
            _step([
              [email],
              [phone],
            ]),
          ],
        ),
      );

      expect(find.text("Maak een keuze"), findsOneWidget);
      expect(find.text("Cred email"), findsOneWidget);
      expect(find.text("Cred phone"), findsOneWidget);

      await tester.tap(find.text("Cred phone"));
      await tester.pump();

      expect(
        container
            .read(issueDuringDisclosureProvider(_sessionId))
            .selectedOptionPerStep,
        [1],
      );
    });

    testWidgets("becomes the share screen when nothing is missing", (
      tester,
    ) async {
      await setUpScreen(tester, flagOn: true);
      await emit(tester, _session(steps: twoSteps));
      await emit(
        tester,
        _session(
          steps: twoSteps,
          issued: {"email", "phone"},
          withChoices: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Alles staat klaar"), findsOneWidget);
      expect(
        find.text("Wil je deze 2 gegevens delen met Test Verifier?"),
        findsOneWidget,
      );
      expect(find.text("Delen"), findsOneWidget);
      expect(find.text("Nog niet in je app"), findsNothing);
      expect(find.text("Volgende stap"), findsNothing);

      final header = tester.widget<Container>(
        find.byKey(const Key("missing_data_header")),
      );
      expect((header.decoration as BoxDecoration).color, IrmaThemeData().link);
    });

    testWidgets("keeps today's screens when the flag is off", (tester) async {
      await setUpScreen(tester, flagOn: false);
      await emit(tester, _session(steps: twoSteps));

      expect(find.text("Stap 1 van 2"), findsOneWidget);
      expect(find.text("Test Verifier vraagt om 2 gegevens"), findsNothing);
      expect(find.byKey(const Key("missing_data_header")), findsNothing);
    });

    testWidgets("keeps today's screens for sessions that are not disclosures", (
      tester,
    ) async {
      await setUpScreen(tester, flagOn: true);
      await emit(
        tester,
        _session(steps: twoSteps, type: SessionType.signature),
      );

      expect(find.byKey(const Key("missing_data_header")), findsNothing);
    });
  });
}

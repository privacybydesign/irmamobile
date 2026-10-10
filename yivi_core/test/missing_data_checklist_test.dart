import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/missing_data_checklist.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/providers/issue_during_disclosure_provider.dart";
import "package:yivi_core/src/providers/missing_data_flow_provider.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/util/navigation.dart";
import "package:yivi_core/src/widgets/irma_card.dart";
import "package:yivi_core/src/widgets/yivi_themed_button.dart";

import "missing_data_fixtures.dart";

IssueDuringDisclosureState _wizard(
  List<IssuanceStep> steps, {
  Set<String> issued = const {},
  List<int>? selections,
}) => IssueDuringDisclosureState(
  steps: steps,
  selectedOptionPerStep: selections ?? List.filled(steps.length, 0),
  issuedCredentialIds: issued,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("MissingDataChecklist", () {
    final email = testDescriptor("email");
    final phone = testDescriptor("phone");

    test("counts the credentials of every step", () {
      final checklist = MissingDataChecklist.fromWizardState(
        _wizard([
          testStep([
            [email],
          ]),
          testStep([
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
            testStep([
              [email],
            ]),
            testStep([
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
            testStep([
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
          testStep([
            [testDescriptor("elsewhere", issueURL: null)],
          ]),
          testStep([
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
            testStep([
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
        testStep([
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
            testStep([
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
            testStep([
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
    late MissingDataHarness harness;
    late GoRouter router;

    ProviderContainer container() => harness.container;

    Future<void> setUpScreen(
      WidgetTester tester, {
      required bool flagOn,
    }) async {
      router = GoRouter(
        initialLocation: "/session",
        routes: [
          GoRoute(
            path: "/session",
            builder: (_, _) => const SessionScreen(sessionId: testSessionId),
          ),
          GoRoute(
            path: "/session_issue",
            builder: (_, _) => const Scaffold(body: Text("issuance session")),
          ),
          GoRoute(
            path: "/home/add_data/details",
            builder: (_, _) => const Scaffold(body: Text("details screen")),
          ),
        ],
      );
      harness = await MissingDataHarness.pump(tester, router, flagOn: flagOn);
    }

    Future<void> emit(WidgetTester tester, SessionState session) =>
        harness.emit(tester, session);

    final email = testDescriptor("email");
    final phone = testDescriptor("phone");
    final twoSteps = [
      testStep([
        [email],
      ]),
      testStep([
        [phone],
      ]),
    ];

    testWidgets("lists the missing credentials, the first one ringed", (
      tester,
    ) async {
      await setUpScreen(tester, flagOn: true);
      await emit(tester, testSession(steps: twoSteps));

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
      await emit(tester, testSession(steps: twoSteps));

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
      await emit(tester, testSession(steps: [twoSteps.first]));

      expect(find.text("Test Verifier vraagt om 1 gegeven"), findsOneWidget);
      expect(find.text("Haal eerst het ontbrekende gegeven op"), findsOne);
    });

    testWidgets("flags an unknown requestor", (tester) async {
      await setUpScreen(tester, flagOn: true);
      await emit(tester, testSession(steps: twoSteps, verified: false));

      expect(find.text("Onbekende partij"), findsOneWidget);
    });

    testWidgets("counts up, flashes the new row and moves the ring", (
      tester,
    ) async {
      await setUpScreen(tester, flagOn: true);
      await emit(tester, testSession(steps: twoSteps));
      await emit(tester, testSession(steps: twoSteps, issued: {"email"}));

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
      await emit(tester, testSession(steps: twoSteps));
      await emit(tester, testSession(steps: twoSteps, issued: {"email"}));
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
      await emit(tester, testSession(steps: twoSteps));

      await tester.tap(find.text("Ophalen").last);
      await tester.pumpAndSettle();

      expect(find.text("details screen"), findsOneWidget);
      final flow = container().read(missingDataFlowProvider);
      expect(flow?.sessionId, testSessionId);
      expect(flow?.credentialId, "phone");

      router.pop();
      await tester.pumpAndSettle();

      expect(find.text("details screen"), findsNothing);
      expect(container().read(missingDataFlowProvider), isNull);
    });

    testWidgets("clears the flow when the list becomes the share screen", (
      tester,
    ) async {
      await setUpScreen(tester, flagOn: true);
      await emit(tester, testSession(steps: twoSteps));
      await tester.tap(find.text("Ophalen").last);
      await tester.pumpAndSettle();
      expect(container().read(missingDataFlowProvider), isNotNull);

      await emit(
        tester,
        testSession(
          steps: twoSteps,
          issued: {"email", "phone"},
          withChoices: true,
        ),
      );
      router.pop();
      await tester.pumpAndSettle();

      expect(find.text("Alles staat klaar"), findsOneWidget);
      expect(container().read(missingDataFlowProvider), isNull);
    });

    testWidgets("shows the wrong credential dialog on the list, not on top "
        "of the issuance session", (tester) async {
      await setUpScreen(tester, flagOn: true);
      await emit(tester, testSession(steps: twoSteps));
      router.push("/session_issue");
      await tester.pumpAndSettle();

      await emit(
        tester,
        testSession(steps: twoSteps, wrongCredential: testCredential("email")),
      );
      await tester.pumpAndSettle();

      // The issuance session pops back to the list once it succeeds.
      tester.element(find.text("issuance session")).popToUnderlyingSession();
      await tester.pumpAndSettle();

      expect(find.text("issuance session"), findsNothing);
      expect(find.text("Foutmelding"), findsOneWidget);
    });

    testWidgets("keeps the choice between options", (tester) async {
      await setUpScreen(tester, flagOn: true);
      await emit(
        tester,
        testSession(
          steps: [
            testStep([
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
        container()
            .read(issueDuringDisclosureProvider(testSessionId))
            .selectedOptionPerStep,
        [1],
      );
    });

    testWidgets("becomes the share screen when nothing is missing", (
      tester,
    ) async {
      await setUpScreen(tester, flagOn: true);
      await emit(tester, testSession(steps: twoSteps));
      await emit(
        tester,
        testSession(
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
      await emit(tester, testSession(steps: twoSteps));

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
        testSession(steps: twoSteps, type: SessionType.signature),
      );

      expect(find.byKey(const Key("missing_data_header")), findsNothing);
    });
  });
}

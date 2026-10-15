import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/providers/missing_data_flow_provider.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/add_missing_data_screen.dart";
import "package:yivi_core/src/screens/session/widgets/change_choice_sheet.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "missing_data_fixtures.dart";

// The "Add data first" screen inside a real SessionScreen, driven by the
// session states irmago sends (in Dutch, as the harness runs).

CredentialDescriptor _descriptor(
  String id, {
  bool addable = true,
  List<Attribute> attributes = const [],
}) => CredentialDescriptor(
  credentialId: id,
  name: "Kaart $id",
  issuer: testParty("Uitgever"),
  category: null,
  attributes: attributes,
  issueURL: addable ? "https://www.issuer.example/$id" : null,
);

void main() {
  late MissingDataHarness harness;
  late List<String> opened;

  Future<void> setUp(WidgetTester tester) async {
    opened = [];
    final router = GoRouter(
      initialLocation: "/session",
      routes: [
        GoRoute(
          path: "/session",
          builder: (_, _) => const SessionScreen(sessionId: testSessionId),
        ),
        GoRoute(
          path: "/elsewhere",
          builder: (_, _) => const Scaffold(body: Text("elsewhere")),
        ),
      ],
    );
    harness = await MissingDataHarness.pump(
      tester,
      router,
      overrides: [
        issuerOpenerProvider.overrideWithValue(
          (context, d, ref) async => opened.add(d.credentialId),
        ),
      ],
    );
  }

  Future<void> emit(WidgetTester tester, SessionState s) async {
    await harness.emit(tester, s);
    await tester.pumpAndSettle();
  }

  final email = _descriptor("email");
  final phone = _descriptor("phone");
  final twoSteps = [
    testStep([
      [email],
    ]),
    testStep([
      [phone],
    ]),
  ];
  final addButton = find.byKey(const Key("add_button"));

  testWidgets("one step at a time, one button that adds", (tester) async {
    await setUp(tester);
    await emit(tester, testSession(steps: twoSteps));

    expect(find.byType(AddMissingDataScreen), findsOneWidget);
    expect(find.text("Eerst gegevens toevoegen"), findsOneWidget);
    expect(find.text("Stap 1 van 2"), findsOneWidget);
    expect(find.text("Voeg kaart email toe"), findsWidgets);
    expect(find.text("Volgende"), findsOneWidget);
    expect(find.text("Opent issuer.example"), findsOneWidget);

    await tester.tap(addButton);
    await tester.pumpAndSettle();
    expect(opened, ["email"]);
    // The in-app flows show the band back to this screen.
    expect(
      harness.container.read(missingDataFlowProvider)?.credentialId,
      "email",
    );
  });

  testWidgets("an added step folds away and the next one is current", (
    tester,
  ) async {
    await setUp(tester);
    await emit(tester, testSession(steps: twoSteps, issued: {"email"}));

    expect(find.text("Toegevoegd"), findsOneWidget);
    expect(find.text("Stap 2 van 2"), findsOneWidget);
    expect(find.text("Voeg kaart phone toe"), findsWidgets);
  });

  testWidgets("a choice: radio rows, and the button follows the pick", (
    tester,
  ) async {
    await setUp(tester);
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

    expect(find.text("Welke wil je toevoegen?"), findsOneWidget);
    expect(find.text("Uitgever · op issuer.example"), findsNWidgets(2));
    expect(
      find.descendant(
        of: addButton,
        matching: find.text("Voeg kaart email toe"),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key("add_option_0_1")));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: addButton,
        matching: find.text("Voeg kaart phone toe"),
      ),
      findsOneWidget,
    );
  });

  testWidgets("an option Yivi cannot add starts unselected and stays so", (
    tester,
  ) async {
    await setUp(tester);
    await emit(
      tester,
      testSession(
        steps: [
          testStep([
            [_descriptor("member", addable: false)],
            [phone],
          ]),
        ],
      ),
    );

    expect(find.text("Kan niet vanuit Yivi worden toegevoegd"), findsOneWidget);
    expect(
      find.descendant(
        of: addButton,
        matching: find.text("Voeg kaart phone toe"),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key("add_option_0_0")));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: addButton,
        matching: find.text("Voeg kaart phone toe"),
      ),
      findsOneWidget,
    );
  });

  testWidgets("nothing can be added: Close, and where to get it", (
    tester,
  ) async {
    await setUp(tester);
    await emit(
      tester,
      testSession(
        steps: [
          testStep([
            [_descriptor("voting", addable: false)],
          ]),
        ],
      ),
    );

    expect(
      find.text(
        "Yivi kan kaart voting niet toevoegen. Haal het eerst bij Uitgever "
        "en scan daarna de QR-code opnieuw.",
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: addButton, matching: find.text("Sluiten")),
      findsOneWidget,
    );
  });

  testWidgets("cards that go together are added one by one", (tester) async {
    await setUp(tester);
    final root = _descriptor("root");
    final fullName = _descriptor("fullname");
    await emit(
      tester,
      testSession(
        steps: [
          testStep([
            [root, fullName],
          ]),
        ],
        issued: {"root"},
      ),
    );

    expect(find.byKey(const Key("add_checklist")), findsOneWidget);
    expect(find.text("Deze worden één voor één toegevoegd"), findsOneWidget);
    expect(
      find.descendant(
        of: addButton,
        matching: find.text("Voeg kaart fullname toe"),
      ),
      findsOneWidget,
    );
  });

  testWidgets("a required value, and a card that does not match it", (
    tester,
  ) async {
    await setUp(tester);
    final bank = _descriptor(
      "bank",
      attributes: [
        Attribute(
          claimPath: ["bic"],
          displayName: "BIC",
          requestedValue: AttributeValue(
            type: AttributeType.string,
            string: "RABONL2U",
          ),
        ),
      ],
    );
    final step = testStep([
      [bank],
    ]);
    await emit(tester, testSession(steps: [step]));
    expect(find.text("moet RABONL2U zijn"), findsOneWidget);
    expect(find.byKey(const Key("add_wrong_note")), findsNothing);

    await emit(
      tester,
      testSession(
        steps: [step],
        wrongCredential: Credential(
          credentialId: "bank",
          hash: "wrong",
          name: "Kaart bank",
          issuer: testParty("Uitgever"),
          credentialInstanceIds: const {},
          batchInstanceCountsRemaining: const {},
          attributes: [
            Attribute(
              claimPath: ["bic"],
              displayName: "BIC",
              value: AttributeValue(
                type: AttributeType.string,
                string: "INGBNL2A",
              ),
            ),
          ],
          revoked: false,
          revocationSupported: false,
          issueUrl: null,
        ),
      ),
    );

    // In place, not in a dialog.
    expect(find.byType(Dialog), findsNothing);
    expect(find.byKey(const Key("add_wrong_note")), findsOneWidget);
    expect(find.text("INGBNL2A"), findsOneWidget);
    expect(find.text("RABONL2U"), findsOneWidget);
    expect(
      find.descendant(of: addButton, matching: find.text("Opnieuw toevoegen")),
      findsOneWidget,
    );
  });

  testWidgets("once nothing is missing: the share screen, no Next step", (
    tester,
  ) async {
    await setUp(tester);
    await emit(tester, testSession(steps: twoSteps));
    await emit(
      tester,
      testSession(
        steps: twoSteps,
        issued: {"email", "phone"},
        withChoices: true,
      ),
    );

    expect(find.byType(DisclosureShareScreen), findsOneWidget);
    expect(
      find.text("Alles is toegevoegd. Controleer wat je deelt."),
      findsOneWidget,
    );
    expect(find.text("Volgende stap"), findsNothing);
  });

  testWidgets("the band's flow ends when the session screen goes", (
    tester,
  ) async {
    await setUp(tester);
    await emit(tester, testSession(steps: twoSteps));
    await tester.tap(addButton);
    await tester.pumpAndSettle();
    expect(harness.container.read(missingDataFlowProvider), isNotNull);

    final context = tester.element(find.byType(AddMissingDataScreen));
    GoRouter.of(context).go("/elsewhere");
    await tester.pumpAndSettle();
    expect(harness.container.read(missingDataFlowProvider), isNull);
  });
}

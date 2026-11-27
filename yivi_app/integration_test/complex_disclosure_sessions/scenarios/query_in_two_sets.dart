import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../complex_disclosure_helpers.dart";

/// One query (mail) in two sets: picking another address in one place picks
/// it in the other, and the sheet says it counts for two questions.
Future<void> queryInTwoSetsTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmails(tester, irmaBinding, ["a@one.example", "b@two.example"]);
  await issuePhones(tester, irmaBinding, ["0611111111"]);

  await startDcql(tester, irmaBinding, {
    "credentials": [mailQuery("mail"), phoneQuery("phone")],
    "credential_sets": [
      {
        "options": [
          ["mail"],
          ["phone"],
        ],
      },
      {
        "options": [
          ["mail", "phone"],
        ],
      },
    ],
  });

  await changeChoice(tester, 0);
  expect(find.byKey(const Key("which_card_linked")), findsOneWidget);
  await pickOwned(tester, "b@two.example");

  // Both places now share the second address, listed once.
  await toOverview(tester);
  expect(inValues("b@two.example"), findsOneWidget);
  expect(inValues("a@one.example"), findsNothing);
  await tapShare(tester);
  await evaluateFeedback(tester);
  await expectInLatestActivity(
    tester,
    irmaBinding,
    ["b@two.example"],
    notShared: ["a@one.example"],
  );
}

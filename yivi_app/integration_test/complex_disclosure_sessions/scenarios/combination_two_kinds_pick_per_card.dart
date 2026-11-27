import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../complex_disclosure_helpers.dart";

/// One set, one option of two cards: an e-mail address and a phone number,
/// each picked in its own sheet.
Future<void> combinationTwoKindsPickPerCardTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmails(tester, irmaBinding, ["a@one.example", "b@two.example"]);
  await issuePhones(tester, irmaBinding, [
    "0611111111",
    "0622222222",
    "0633333333",
  ]);

  await startDcql(tester, irmaBinding, {
    "credentials": [mailQuery("mail"), phoneQuery("phone")],
    "credential_sets": [
      {
        "options": [
          ["mail", "phone"],
        ],
      },
    ],
  });

  // Everything is in the app: no add step, one e-mail and one phone.
  expect(find.byKey(const Key("add_step")), findsNothing);
  expect(find.byKey(const Key("share_overview")), findsOneWidget);
  expect(find.text("Email address"), findsWidgets);
  expect(find.text("Mobile phone number"), findsWidgets);

  // The change page: one card with two slots, each with its own link.
  await openChangePage(tester);
  expect(find.byKey(const Key("change_pick_slot_0_mail")), findsOneWidget);
  expect(find.byKey(const Key("change_pick_slot_0_phone")), findsOneWidget);
  expect(find.byKey(const Key("change_combination_0")), findsNothing);

  await pickInSlot(tester, 0, "mail", "b@two.example");
  await pickInSlot(tester, 0, "phone", "0633333333");

  await toOverview(tester);
  expect(inValues("b@two.example"), findsOneWidget);
  expect(inValues("0633333333"), findsOneWidget);
  await tapShare(tester);
  await evaluateFeedback(tester);
  await expectInLatestActivity(
    tester,
    irmaBinding,
    ["b@two.example", "0633333333"],
    notShared: ["a@one.example", "0611111111"],
  );
}

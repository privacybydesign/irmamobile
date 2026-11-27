import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../complex_disclosure_helpers.dart";

/// Two required sets, each of two options of two cards (the canvas stress
/// test): change one card in set A and the combination in set B.
Future<void> twoSetsStressTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  bool secondOptional = false,
}) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmails(tester, irmaBinding, [
    "a@one.example",
    "b@two.example",
    "c@three.example",
  ]);
  await issuePhones(tester, irmaBinding, ["0611111111", "0622222222"]);

  await startDcql(tester, irmaBinding, {
    "credentials": [
      mailQuery("mA"),
      phoneQuery("pA"),
      domainQuery("dA"),
      phoneQuery("pA2"),
      mailQuery("mB"),
      phoneQuery("pB"),
      domainQuery("dB"),
      phoneQuery("pB2"),
    ],
    "credential_sets": [
      {
        "options": [
          ["mA", "pA"],
          ["dA", "pA2"],
        ],
      },
      {
        if (secondOptional) "required": false,
        "options": [
          ["mB", "pB"],
          ["dB", "pB2"],
        ],
      },
    ],
  });

  if (secondOptional) {
    expect(find.byKey(const Key("share_optional_hint")), findsOneWidget);
    await openChangePage(tester);
    final link = find.byKey(const Key("change_optional_link_1"));
    expect(find.text("Two options"), findsOneWidget);
    expect(
      find.descendant(of: link, matching: find.text("Choose a combination")),
      findsOneWidget,
    );
    await openOptionalSheet(tester, 1);
    await tester.tapAndSettle(find.byKey(const Key("combination_option_0")));
    await chooseInSheet(tester);
    await toOverview(tester);
    expect(find.byKey(const Key("share_optional_card_1")), findsOneWidget);
    await removeOptional(tester, 1);
    await toOverview(tester);
    await tapShare(tester);
    await evaluateFeedback(tester);
    return;
  }

  await openChangePage(tester);
  expect(find.byKey(const Key("change_combination_0")), findsOneWidget);
  expect(find.byKey(const Key("change_combination_1")), findsOneWidget);
  await pickInSlot(tester, 0, "mA", "c@three.example");
  await tester.ensureVisible(find.byKey(const Key("change_combination_1")));
  await tester.pumpAndSettle();
  await tester.tapAndSettle(find.byKey(const Key("change_combination_1")));
  await tester.tapAndSettle(find.byKey(const Key("combination_option_1")));
  await chooseInSheet(tester);
  expect(find.byKey(const Key("change_slot_1_dB")), findsOneWidget);

  await toOverview(tester);
  expect(inValues("c@three.example"), findsOneWidget);
  await tapShare(tester);
  await evaluateFeedback(tester);
  await expectInLatestActivity(tester, irmaBinding, ["c@three.example"]);
}

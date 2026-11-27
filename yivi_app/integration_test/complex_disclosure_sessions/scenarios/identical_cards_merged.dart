import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../complex_disclosure_helpers.dart";

/// Two e-mail cards of one domain, asked only for the domain: one row in the
/// sheet, "two cards with the same data", nothing to pick.
Future<void> identicalCardsMergedTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmails(tester, irmaBinding, ["a@same.example", "b@same.example"]);

  await startDcql(tester, irmaBinding, {
    "credentials": [domainQuery("dom")],
  });

  expect(inValues("same.example"), findsOneWidget);
  await changeChoice(tester, 0);
  expect(findSheetOwnedRows(), findsOneWidget);
  expect(find.text("two cards with the same data"), findsOneWidget);
  expect(find.byKey(const Key("which_card_choose")), findsNothing);
  await closeChoiceSheet(tester);
  await tapShare(tester);
  await evaluateFeedback(tester);
}

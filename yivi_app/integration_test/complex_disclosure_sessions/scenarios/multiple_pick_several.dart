import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../complex_disclosure_helpers.dart";

/// A query that takes several cards: all are picked at first (D7); untick
/// one in "Choose which you share".
Future<void> multiplePickSeveralTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmails(tester, irmaBinding, [
    "a@one.example",
    "b@two.example",
    "c@three.example",
  ]);

  await startDcql(tester, irmaBinding, {
    "credentials": [
      query("mail", emailVct, paths: ["email"], multiple: true),
    ],
  });

  for (final e in ["a@one.example", "b@two.example", "c@three.example"]) {
    expect(inValues(e), findsOneWidget);
  }
  await openChangePage(tester);
  await tester.tapAndSettle(find.byKey(const Key("change_pick_0")));
  expect(find.text("Which cards do you share?"), findsWidgets);
  await tester.tapAndSettle(findSheetOwnedRowShowing("b@two.example"));
  await chooseInSheet(tester);

  await toOverview(tester);
  expect(inValues("b@two.example"), findsNothing);
  expect(find.text("From two cards in your app"), findsOneWidget);
  await tapShare(tester);
  await evaluateFeedback(tester);
  await expectInLatestActivity(
    tester,
    irmaBinding,
    ["a@one.example", "c@three.example"],
    notShared: ["b@two.example"],
  );
}

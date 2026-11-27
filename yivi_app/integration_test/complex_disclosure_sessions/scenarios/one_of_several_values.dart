import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../complex_disclosure_helpers.dart";

/// A query on the domain with two allowed values: only the matching card is
/// offered and shared.
Future<void> oneOfSeveralValuesTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmails(tester, irmaBinding, [
    "a@second.example",
    "b@other.example",
  ]);

  await startDcql(tester, irmaBinding, {
    "credentials": [
      mailQuery("mail", values: ["first.example", "second.example"]),
    ],
  });

  expect(inValues("second.example"), findsOneWidget);
  expect(find.text("other.example"), findsNothing);
  await tapShare(tester);
  await evaluateFeedback(tester);
  await expectInLatestActivity(
    tester,
    irmaBinding,
    ["second.example"],
    notShared: ["other.example"],
  );
}

/// The same with an empty wallet: the add step's tag lists both values.
Future<void> oneOfSeveralValuesEmptyTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await startDcql(tester, irmaBinding, {
    "credentials": [
      mailQuery("mail", values: ["first.example", "second.example"]),
    ],
  });

  expect(
    find.descendant(
      of: findEmptySpot(0),
      matching: find.textContaining("first.example or second.example"),
    ),
    findsOneWidget,
  );
  await tester.tapAndSettle(find.byKey(const Key("session_close")));
  await tester.tapAndSettle(find.text("Yes"));
}

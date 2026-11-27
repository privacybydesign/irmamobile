import "package:flutter_test/flutter_test.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../complex_disclosure_helpers.dart";

/// One option of two e-mail queries: they start on two different addresses,
/// and both may be the same one (D4).
Future<void> sameKindTwiceTest(
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
    "credentials": [mailQuery("mailA"), mailQuery("mailB")],
    "credential_sets": [
      {
        "options": [
          ["mailA", "mailB"],
        ],
      },
    ],
  });

  // Two different addresses by default.
  final shown = [
    for (final e in ["a@one.example", "b@two.example", "c@three.example"])
      if (inValues(e).evaluate().isNotEmpty) e,
  ];
  expect(shown, hasLength(2));

  // The same address for both is allowed.
  await pickInSlot(tester, 0, "mailB", shown.first);
  await toOverview(tester);
  await tapShare(tester);
  await evaluateFeedback(tester);
  await expectInLatestActivity(tester, irmaBinding, [shown.first]);
}

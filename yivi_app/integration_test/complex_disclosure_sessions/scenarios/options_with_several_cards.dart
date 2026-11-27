import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../complex_disclosure_helpers.dart";

/// One set with two options, [mail + phone] and [domain]: the default is the
/// first; "Choose another combination" lists both, complete first.
Future<void> optionsWithSeveralCardsTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmails(tester, irmaBinding, ["a@one.example", "b@two.example"]);
  await issuePhones(tester, irmaBinding, ["0611111111"]);

  await startDcql(tester, irmaBinding, {
    "credentials": [mailQuery("mail"), phoneQuery("phone"), domainQuery("dom")],
    "credential_sets": [
      {
        "options": [
          ["mail", "phone"],
          ["dom"],
        ],
      },
    ],
  });

  expect(inValues("0611111111"), findsOneWidget);
  await openChangePage(tester);
  await tester.tapAndSettle(find.byKey(const Key("change_combination_0")));
  expect(find.byKey(const Key("which_combination_sheet")), findsOneWidget);
  final first = tester.getTopLeft(
    find.byKey(const Key("combination_option_0")),
  );
  final second = tester.getTopLeft(
    find.byKey(const Key("combination_option_1")),
  );
  expect(first.dy, lessThan(second.dy));
  await tester.tapAndSettle(find.byKey(const Key("combination_option_1")));
  await chooseInSheet(tester);

  await toOverview(tester);
  expect(inValues("0611111111"), findsNothing);
  expect(find.text("Email domain name"), findsWidgets);
  await tapShare(tester);
  await evaluateFeedback(tester);
  // The domain of irmago's first candidate: the newest card.
  await expectInLatestActivity(
    tester,
    irmaBinding,
    ["two.example"],
    notShared: ["one.example"],
  );
}

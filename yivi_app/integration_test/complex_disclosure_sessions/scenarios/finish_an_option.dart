import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../complex_disclosure_helpers.dart";

/// One e-mail address, no phone; options [mail + phone] and [phone2]: one
/// add-step row with two ways, the one you hold part of first.
Future<void> finishAnOptionTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmails(tester, irmaBinding, ["a@one.example"]);

  await startDcql(tester, irmaBinding, {
    "credentials": [
      mailQuery("mail"),
      phoneQuery("phone"),
      domainQuery("dom2"),
    ],
    "credential_sets": [
      {
        "options": [
          ["mail", "phone"],
          ["phone"],
        ],
      },
    ],
  });

  expect(findEmptySpot(0), findsOneWidget);
  expect(
    find.descendant(
      of: findEmptySpot(0),
      matching: find.text("Choose from two options"),
    ),
    findsOneWidget,
  );
  await tapSpot(tester, 0);
  expect(find.byKey(const Key("add_picker")), findsOneWidget);
  // The way that only misses the phone comes first, with what is in the app.
  final withMail = find.byKey(const Key("add_picker_row_0"));
  final alone = find.byKey(const Key("add_picker_row_1"));
  expect(tester.getTopLeft(withMail).dy, lessThan(tester.getTopLeft(alone).dy));
  expect(
    find.descendant(
      of: withMail,
      matching: find.textContaining("Together with"),
    ),
    findsOneWidget,
  );
  await startAdding(tester, mobileId);
  await issueMobileNumber(tester, irmaBinding, sdJwtBatchSize: 10);
  await expectAddedInPlace(tester, 0);
  await tapShare(tester);
  await evaluateFeedback(tester);
}

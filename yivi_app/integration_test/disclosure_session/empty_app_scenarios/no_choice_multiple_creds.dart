import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../disclosure_helpers.dart";

Future<void> noChoiceMultipleCredsTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Session requesting:
  // Email AND mobile number
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email"]
            ],
            [
              [ "irma-demo.sidn-pbdf.mobilenumber.mobilenumber"]
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);

  // Two empty spots, each with one way to fill it. Share waits for the
  // e-mail address first.
  const sidn = "Demo Privacy by Design Foundation via SIDN";
  await waitForRequest(tester);
  expectEmptySpot(0, "Demo Email address", hint: sidn);
  expectEmptySpot(
    1,
    "Demo Mobile phone number",
    hint: sidn,
  );
  // Each spot lists the field it will share, still empty.
  expectEmptySpotRows(0, ["Email address"]);
  expectEmptySpotRows(1, ["Mobile phone number"]);
  expectShareWaitsFor(tester, "Demo Email address");

  // The e-mail spot opens its details at once; "Add" opens the website
  // while the sheet waits, and the issuance shows in the sheet.
  await tapSpot(tester, 0);
  await tapAddOnDetails(tester);
  await issueEmailAddress(tester, irmaBinding);
  await expectAddedInPlace(tester, 0);

  // The mobile number is next; it comes in without the sheet.
  expectShareWaitsFor(tester, "Demo Mobile phone number");
  await issueMobileNumber(tester, irmaBinding);
  await expectAddedInPlace(tester, 1);

  // A Change button on both: another e-mail address or number can still be
  // added.
  expect(find.byKey(const Key("share_change_0")), findsOneWidget);
  expect(find.byKey(const Key("share_change_1")), findsOneWidget);
  await tapShare(tester);
  await evaluateFeedback(tester);
}

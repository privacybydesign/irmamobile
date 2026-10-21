import "package:flutter_test/flutter_test.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../disclosure_helpers.dart";

Future<void> choiceTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Session requesting:
  // Email OR your mobile number.
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email" ],
              [ "irma-demo.sidn-pbdf.mobilenumber.mobilenumber" ]
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);

  // The request shows at once: the one requested item is an empty spot,
  // which the e-mail address or the mobile number fills. Share waits for it.
  await waitForRequest(tester);
  expectEmptySpot(
    0,
    "Demo Email address or Demo Mobile phone number",
    hint: "You pick one when adding",
  );
  expectShareWaitsFor(tester, "Demo Email address or Demo Mobile phone number");

  // The spot opens the sheet on the choice; the e-mail address is added
  // there: its details, then "Add" opens the issuer's website while the
  // sheet waits.
  await tapSpot(tester, 0);
  expect(findSheetAddRow("irma-demo.sidn-pbdf.email"), findsOneWidget);
  expect(findSheetAddRow("irma-demo.sidn-pbdf.mobilenumber"), findsOneWidget);
  await startAdding(tester, "irma-demo.sidn-pbdf.email");

  // The test issues the card the way that website would. The issuance shows
  // in the sheet; "Back to …" closes it and the card is in its place.
  await issueEmailAddress(tester, irmaBinding);
  await expectAddedInPlace(tester, 0);
  expect(shareButtonEnabled(tester), isTrue);
  await tapShare(tester);
  await evaluateFeedback(tester);
}

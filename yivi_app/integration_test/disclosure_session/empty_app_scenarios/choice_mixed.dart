import "package:flutter_test/flutter_test.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../disclosure_helpers.dart";

Future<void> choiceMixedTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Session requesting:
  // Address from multiplicity OR address from iDIN
  // AND your AGB code (from Nuts)
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.gemeente.address.street", "irma-demo.gemeente.address.houseNumber", "irma-demo.gemeente.address.city" ],
              [ "irma-demo.idin.idin.address", "irma-demo.idin.idin.city"]
            ],
            [
              [ "irma-demo.nuts.agb.agbcode"]
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);

  // The request shows at once with two empty spots: the address (from the
  // municipality or from iDIN) and the AGB code. Share waits for the first.
  await waitForRequest(tester);
  expectEmptySpot(
    0,
    "Demo Address or Demo iDIN",
    hint: "You pick one when adding",
  );
  expectEmptySpot(1, "Demo Vektis agb by Nuts");
  expectShareWaitsFor(tester, "Demo Address or Demo iDIN");

  // The address spot offers both, each saying where it is added. iDIN is
  // picked: its details, then "Add" opens the website while the sheet
  // waits.
  await tapSpot(tester, 0);
  expectSheetAddRow(
    "irma-demo.gemeente.address",
    "Demo Address",
    "Demo Municipality",
  );
  expectSheetAddRow("irma-demo.idin.idin", "Demo iDIN", "Demo iDIN");
  await startAdding(tester, "irma-demo.idin.idin");

  // The test issues the card the way that website would; it shows in the
  // sheet and lands in its spot.
  await issueIdin(tester, irmaBinding);
  await expectAddedInPlace(tester, 0);
  // Its name and its issuer are both "Demo iDIN".
  expect(findCardText(findShareSlot(0), "Demo iDIN"), findsWidgets);

  // The AGB code is what Share waits for now.
  expectShareWaitsFor(tester, "Demo Vektis agb by Nuts");

  // It comes in without the sheet, on top of the request.
  await issueCredentials(tester, irmaBinding, {
    "irma-demo.nuts.agb.agbcode": "7722255556",
  });
  await expectAddedInPlace(tester, 1);

  await tapShare(tester);
  await evaluateFeedback(tester);
}

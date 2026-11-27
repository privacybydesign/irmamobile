import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/requestor/requestor_card.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../disclosure_helpers.dart";

Future<void> noChoiceTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Session requesting:
  // Full name AND nationality
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.gemeente.personalData.fullname", "irma-demo.gemeente.personalData.nationality" ]
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);

  // The request shows at once: the card is an empty spot with one way to
  // fill it, and Share waits for it.
  await waitForRequest(tester);
  expectEmptySpot(0, "Demo Personal data");
  expectShareWaitsFor(tester, "Demo Personal data");
  await evaluateRequestorHeader(
    tester,
    null,
    localizedRequestorName: "is.demo.staging.yivi.app",
    isVerified: false,
  );

  // The card arrives without the sheet (as from a QR code scanned meanwhile):
  // its issuance shows on top of the request and leads back to it.
  await issueMunicipalityPersonalData(tester, irmaBinding);

  // The card is in its place, added and selected. There is nothing to
  // choose, so no "Change".
  await expectAddedInPlace(tester, 0);
  await expectCanChange(tester, 0, false);

  final requestorHeaderFinder = find.byType(RequestorCard);
  await evaluateRequestorHeader(
    tester,
    requestorHeaderFinder,
    localizedRequestorName: "is.demo.staging.yivi.app",
    isVerified: false,
  );

  await tapShare(tester);
  await evaluateFeedback(tester);
}

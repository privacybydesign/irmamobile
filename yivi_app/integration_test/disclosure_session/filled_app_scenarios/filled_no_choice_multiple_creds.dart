import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
import "package:yivi_core/src/screens/session/widgets/session_requestor_header.dart";
import "package:yivi_core/src/widgets/irma_card.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../disclosure_helpers.dart";
import "sheet_checks.dart";

Future<void> filledNoChoiceMultipleCredsTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueDemoCredentials(tester, irmaBinding);

  // Session requesting:
  // Email AND mobile number
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email" ]
            ],
            [
              [ "irma-demo.sidn-pbdf.mobilenumber.mobilenumber" ]
            ]
          ]
        }
      ''';

  // Start session without the credential being present
  await irmaBinding.repository.startTestSession(sessionRequest);

  // The request shows at once: the e-mail address in place, the mobile
  // number an empty spot that Share waits for.
  await waitForRequest(tester);
  expect(findShareSlot(0), findsOneWidget);
  expectEmptySpot(1, "Demo Mobile phone number");
  expectShareWaitsFor(tester, "Demo Mobile phone number");

  // Something unrelated is added first: the spot stays.
  await issueMunicipalityPersonalData(tester, irmaBinding);
  expect(findEmptySpot(1), findsOneWidget);
  expectShareWaitsFor(tester, "Demo Mobile phone number");

  // The issuer adds the mobile number: it lands in its spot.
  await issueMobileNumber(tester, irmaBinding);
  await expectAddedInPlace(tester, 1);

  // The requestor header should be present
  expect(find.byType(RequestorCard), findsOneWidget);

  // Two cards should be visible: email and mobile phone
  final cardsFinder = findCredentialCards();
  expect(cardsFinder, findsNWidgets(2));
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: "Demo Email address",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: [("Email address", "test@example.com")],
    style: IrmaCardStyle.normal,
  );
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    credentialName: "Demo Mobile phone number",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: [("Mobile phone number", "0612345678")],
    style: IrmaCardStyle.normal,
  );

  // Change the e-mail address: one in the app (shown by its value), and
  // another one can be added.
  await changeChoice(tester, 0);
  expectSheet(
    tester,
    owned: ["test@example.com"],
    selected: "test@example.com",
    addable: ["irma-demo.sidn-pbdf.email"],
  );

  // Close it without changing anything.
  await closeChoiceSheet(tester);
  expect(find.byType(DisclosureShareScreen), findsOneWidget);

  // Now two filled cards should be visible
  expect(cardsFinder, findsNWidgets(2));
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: "Demo Email address",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: [("Email address", "test@example.com")],
    style: IrmaCardStyle.normal,
  );
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    credentialName: "Demo Mobile phone number",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: [("Mobile phone number", "0612345678")],
    style: IrmaCardStyle.normal,
  );

  await tapShare(tester);
  await evaluateFeedback(tester);
}

import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
import "package:yivi_core/src/widgets/irma_card.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../disclosure_helpers.dart";
import "sheet_checks.dart";

Future<void> filledChoiceTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueDemoCredentials(tester, irmaBinding);

  // Session requesting:
  // Email OR
  // Mobile number
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
  await waitForRequest(tester);

  // Expect the choices screen
  expect(find.byType(DisclosureShareScreen), findsOneWidget);

  // Expect one credential card to be present
  final cardFinder = findCredentialCards();
  expect(cardFinder, findsOneWidget);

  // Card should be filled and have correct header
  await evaluateCredentialCard(
    tester,
    cardFinder,
    credentialName: "Demo Email address",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: [("Email address", "test@example.com")],
    style: IrmaCardStyle.normal,
  );

  // Change the choice: the sheet has the e-mail address in the app, and
  // both types can be added.
  await changeChoice(tester, 0);
  expectSheet(
    tester,
    owned: ["Demo Email address"],
    selected: "Demo Email address",
    addable: [_email, _mobile],
  );

  // Add a mobile number: the confirm view, then (as the issuer would)
  // issue it. Something unrelated is issued first; it changes nothing.
  await startAdding(tester, _mobile);
  await issueMunicipalityPersonalData(tester, irmaBinding);
  await issueMobileNumber(tester, irmaBinding);

  // Back on the share screen with the new mobile number selected.
  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  expect(findChoiceSheet(), findsNothing);
  expect(cardFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardFinder.first,
    credentialName: "Demo Mobile phone number",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: [("Mobile phone number", "0612345678")],
    style: IrmaCardStyle.normal,
  );

  // The sheet now has both cards in the app, the mobile number selected.
  await changeChoice(tester, 0);
  expectSheet(
    tester,
    owned: ["Demo Email address", "Demo Mobile phone number"],
    selected: "Demo Mobile phone number",
    addable: [_email, _mobile],
  );

  // Keep it as it is.
  await closeChoiceSheet(tester);
  expect(find.byType(DisclosureShareScreen), findsOneWidget);

  await evaluateRequestorHeader(
    tester,
    null,
    localizedRequestorName: "is.demo.staging.yivi.app",
    isVerified: false,
  );

  // Only the selected card is shared.
  expect(cardFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardFinder.first,
    credentialName: "Demo Mobile phone number",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: [("Mobile phone number", "0612345678")],
    style: IrmaCardStyle.normal,
  );

  await tapShare(tester);
  await evaluateFeedback(tester);
}

const _email = "irma-demo.sidn-pbdf.email";
const _mobile = "irma-demo.sidn-pbdf.mobilenumber";

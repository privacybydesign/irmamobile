import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
import "package:yivi_core/src/screens/session/widgets/session_requestor_header.dart";
import "package:yivi_core/src/widgets/irma_card.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
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

  // The mobile number is missing: one step to add it first.
  await tester.waitFor(findAddScreen());
  expect(findAddStep(0), findsOneWidget);
  expect(findAddStep(1), findsNothing);
  expect(find.text("Add demo Mobile phone number"), findsWidgets);
  expectAddButtonFor(tester, "Demo Mobile phone number");

  // Something unrelated is added first: the step stays.
  await issueMunicipalityPersonalData(tester, irmaBinding);
  expect(findAddScreen(), findsOneWidget);
  expectAddButtonFor(tester, "Demo Mobile phone number");

  // The issuer adds the mobile number: the share screen follows by itself.
  await issueMobileNumber(tester, irmaBinding);
  await tester.waitFor(find.byType(DisclosureShareScreen));
  expect(find.byKey(const Key("share_added_banner")), findsOneWidget);

  // The requestor header should be present
  expect(find.byType(SessionRequestorHeader), findsOneWidget);

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

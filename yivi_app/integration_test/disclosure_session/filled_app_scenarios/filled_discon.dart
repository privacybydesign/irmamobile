import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
import "package:yivi_core/src/screens/session/widgets/session_requestor_header.dart";
import "package:yivi_core/src/widgets/irma_card.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../disclosure_helpers.dart";
import "sheet_checks.dart";

Future<void> filledDisconTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueDemoCredentials(tester, irmaBinding);

  // Session requesting:
  // Address from municipality OR iDIN
  // AND mobile number
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.gemeente.address.street", "irma-demo.gemeente.address.houseNumber", "irma-demo.gemeente.address.city" ],
              [ "irma-demo.idin.idin.address", "irma-demo.idin.idin.city" ]
            ],
            [
              [ "irma-demo.sidn-pbdf.email.email" ]
            ]
          ]
        }
      ''';

  // Start session without the credential being present
  await irmaBinding.repository.startTestSession(sessionRequest);
  await waitForRequest(tester);

  // Both cards are already obtained
  // Expect choices screen.
  expect(find.byType(DisclosureShareScreen), findsOneWidget);

  // Expect cards to have the right content
  final cardsFinder = findCredentialCards();

  expect(cardsFinder, findsNWidgets(2));
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: "Demo Address",
    issuerName: "Demo Municipality",
    attributes: [
      ("Street", "Meander"),
      ("House number", "501"),
      ("City", "Arnhem"),
    ],
    style: IrmaCardStyle.normal,
  );
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    credentialName: "Demo Email address",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: [("Email address", "test@example.com")],
    style: IrmaCardStyle.normal,
  );

  // Change the first choice: the address in the app, iDIN can be added.
  await changeChoice(tester, 0);
  expectSheet(
    tester,
    owned: ["Demo Address"],
    selected: "Demo Address",
    addable: [_idin],
  );

  // Add iDIN: the confirm view, then (as the issuer would) issue it.
  await startAdding(tester, _idin);
  await issueIdin(tester, irmaBinding);

  // Back on the share screen with iDIN selected.
  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  await changeChoice(tester, 0);
  expectSheet(
    tester,
    owned: ["Demo Address", "Demo iDIN"],
    selected: "Demo iDIN",
  );
  await closeChoiceSheet(tester);

  // The second choice: one e-mail address in the app (shown by its value,
  // as all options are e-mail addresses), another one can be added.
  await changeChoice(tester, 1);
  expectSheet(
    tester,
    owned: ["test@example.com"],
    selected: "test@example.com",
    addable: [_email],
  );

  // Leave the choices as they are.
  await closeChoiceSheet(tester);
  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  expect(find.byType(RequestorCard), findsOneWidget);

  expect(cardsFinder, findsNWidgets(2));
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: "Demo iDIN",
    issuerName: "Demo iDIN",
    attributes: [("Address", "Meander 501"), ("City", "Arnhem")],
    style: IrmaCardStyle.normal,
  );
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    credentialName: "Demo Email address",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: [("Email address", "test@example.com")],
    style: IrmaCardStyle.normal,
  );

  await tapShare(tester);
  await evaluateFeedback(tester);
}

const _idin = "irma-demo.idin.idin";
const _email = "irma-demo.sidn-pbdf.email";

import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
import "package:yivi_core/src/screens/session/widgets/session_requestor_header.dart";
import "package:yivi_core/src/widgets/irma_card.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";
import "sheet_checks.dart";

Future<void> filledChoiceMixedTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueDemoCredentials(tester, irmaBinding);

  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.gemeente.address.street", "irma-demo.gemeente.address.houseNumber", "irma-demo.gemeente.address.city" ],
              [ "irma-demo.idin.idin.address", "irma-demo.idin.idin.city" ]
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);
  await waitForRequest(tester);

  // Should go straight to overview screen,
  // because the address has already been obtained
  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  await tester.waitFor(find.byType(RequestorCard));

  // Expect the already obtained municipality address
  final cardsFinder = findCredentialCards();
  expect(cardsFinder, findsOneWidget);
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

  // Change the choice: the address in the app, iDIN can be added.
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

  // Back on the share screen with the new iDIN selected.
  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  await tester.waitFor(
    find.byType(RequestorCard),
    timeout: const Duration(seconds: 5),
  );
  expect(cardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: "Demo iDIN",
    issuerName: "Demo iDIN",
    attributes: [("Address", "Meander 501"), ("City", "Arnhem")],
    style: IrmaCardStyle.normal,
  );

  // The sheet now has both cards in the app, iDIN selected.
  await changeChoice(tester, 0);
  expectSheet(
    tester,
    owned: ["Demo Address", "Demo iDIN"],
    selected: "Demo iDIN",
  );
  await closeChoiceSheet(tester);

  // Still the iDIN on the share screen.
  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  expect(find.byType(RequestorCard), findsOneWidget);
  expect(cardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: "Demo iDIN",
    issuerName: "Demo iDIN",
    attributes: [("Address", "Meander 501"), ("City", "Arnhem")],
    style: IrmaCardStyle.normal,
  );

  await tapShare(tester);
  await evaluateFeedback(tester);
}

const _idin = "irma-demo.idin.idin";

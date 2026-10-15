import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/add_data/schemaless_add_data_details_screen.dart";
import "package:yivi_core/src/screens/session/widgets/add_missing_data_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
import "package:yivi_core/src/widgets/irma_card.dart";
import "package:yivi_core/src/widgets/requestor_header.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

Future<void> filledSpecificAttributeValuesNoMatchTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueDemoCredentials(tester, irmaBinding);

  // Email address where domain has to be test.com
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email", { "type" : "irma-demo.sidn-pbdf.email.domain", "value": "sidn.nl" }  ]
            ]
          ]
        }
      ''';
  await irmaBinding.repository.startTestSession(sessionRequest);

  // Expect obtain credential screen
  expect(find.byType(AddMissingDataScreen), findsOneWidget);
  expect(
    find.text(
      "Obtain the required data and share it with the requesting party after that.",
    ),
    findsOneWidget,
  );

  final cardsFinder = findCredentialCards();
  expect(cardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: "Demo Email address",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: [("Email domain name", "sidn.nl")],
    attributesCompareTo: [("Email domain name", "sidn.nl")],
    style: IrmaCardStyle.highlighted,
  );

  await tester.tapAndSettle(find.text("Obtain data"));
  expect(find.byType(SchemalessAddDataDetailsScreen), findsOneWidget);

  // Now obtain the email credential with wrong domain
  await issueCredentials(tester, irmaBinding, {
    "irma-demo.sidn-pbdf.email.email": "test@demo.com",
    "irma-demo.sidn-pbdf.email.domain": "demo.com",
  });

  // Wrong credentials added dialog should appear
  final wrongCredAddedDialogFinder = find.byKey(const Key("add_wrong_note"));
  expect(wrongCredAddedDialogFinder, findsOneWidget);

  // Dialog should show two credential cards
  final dialogCardsFinder = find.descendant(
    of: wrongCredAddedDialogFinder,
    matching: findCredentialCards(),
  );
  expect(dialogCardsFinder, findsNWidgets(2));

  // Evaluate the cards in the dialog
  await evaluateCredentialCard(
    tester,
    dialogCardsFinder.first,
    credentialName: "Demo Email address",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: [("Email domain name", "demo.com")],
    attributesCompareTo: [("Email domain name", "sidn.nl")],
    style: IrmaCardStyle.normal,
  );
  await evaluateCredentialCard(
    tester,
    dialogCardsFinder.at(1),
    credentialName: "Demo Email address",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: [("Email domain name", "sidn.nl")],
    attributesCompareTo: [("Email domain name", "sidn.nl")],
    style: IrmaCardStyle.normal,
  );

  // Close the dialog
  final okButtonFinder = find.text("OK");
  await tester.ensureVisible(okButtonFinder);
  await tester.pumpAndSettle();
  await tester.tapAndSettle(okButtonFinder);

  await tester.tapAndSettle(find.text("Obtain data"));
  expect(find.byType(SchemalessAddDataDetailsScreen), findsOneWidget);

  // Now issue the correct right credential
  await issueCredentials(tester, irmaBinding, {
    "irma-demo.sidn-pbdf.email.email": "test@sidn.nl",
    "irma-demo.sidn-pbdf.email.domain": "sidn.nl",
  });

  // Issue wizard should be completed now
  expect(find.text("All required data has been added."), findsOneWidget);

  // Check the credential card now that is has been completed
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: "Demo Email address",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: [("Email domain name", "sidn.nl")],
    attributesCompareTo: [("Email domain name", "sidn.nl")],
    style: IrmaCardStyle.normal,
  );

  await tester.tapAndSettle(find.text("Next step"));

  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  expect(find.byType(RequestorHeader), findsOneWidget);

  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: "Demo Email address",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: [
      ("Email address", "test@sidn.nl"),
      ("Email domain name", "sidn.nl"),
    ],
    style: IrmaCardStyle.normal,
  );

  await tapShare(tester);
  await evaluateFeedback(tester);
}

import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/session_requestor_header.dart";
import "package:yivi_core/src/widgets/irma_card.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../disclosure_helpers.dart";
import "sheet_checks.dart";

Future<void> filledOptionalDisjunctionTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Issue number from irma-demo.sidn-pbdf
  await issueMobileNumber(tester, irmaBinding);

  // Start session
  await irmaBinding.repository.startTestSession('''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email", "irma-demo.sidn-pbdf.email.domain" ]
            ],
            [
              [],
              [ "irma-demo.pbdf.mobilenumber.mobilenumber" ],
              [ "irma-demo.sidn-pbdf.mobilenumber.mobilenumber" ]
            ]
          ]
        }
      ''');

  // The request shows at once: the e-mail address is an empty spot, the
  // optional mobile number an "Add" row.
  await waitForRequest(tester);
  expectEmptySpot(0, "Demo Email address");
  expect(find.byKey(const Key("share_add_optional_1")), findsOneWidget);
  expectShareWaitsFor(tester, "Demo Email address");

  // The test issues the card the way the issuer's website would: it lands
  // in its spot.
  await issueEmailAddress(tester, irmaBinding);
  await expectAddedInPlace(tester, 0);
  expect(find.byType(RequestorCard), findsOneWidget);

  // The mobile number is optional and starts left out.
  final cardsFinder = findCredentialCards();
  expect(cardsFinder, findsOneWidget);
  expect(findShareSlot(1), findsNothing);

  // Its row opens its sheet: "Share nothing" first and chosen, the mobile
  // number in the app (by its value, as every option is a mobile number),
  // and both kinds can be added.
  await openOptionalSheet(tester, 1);
  expect(
    find.descendant(
      of: findChoiceSheet(),
      matching: find.text("Optional data"),
    ),
    findsOneWidget,
  );
  expect(sheetRowSelected(tester, findShareNothing()), isTrue);
  expectSheet(
    tester,
    owned: ["0612345678"],
    // Not shared yet: no card in the app is the chosen one.
    selected: "",
    addable: [
      "irma-demo.pbdf.mobilenumber",
      "irma-demo.sidn-pbdf.mobilenumber",
    ],
  );

  // Keep the mobile number in the app: the sheet closes and it is shared.
  await pickOwned(tester, "0612345678");
  expect(find.byType(RequestorCard), findsOneWidget);
  expect(findShareSlot(1), findsOneWidget);

  expect(cardsFinder, findsNWidgets(2));
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: "Demo Email address",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: [
      ("Email address", "test@example.com"),
      ("Email domain name", "example.com"),
    ],
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

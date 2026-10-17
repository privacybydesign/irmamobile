import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/session_requestor_header.dart";
import "package:yivi_core/src/widgets/irma_card.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

Future<void> filledSpecificAttributeValuesMatchTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueDemoCredentials(tester, irmaBinding);

  // Address from municipality where city hast to be Arnhem AND
  // Email address where domain has to be test.com
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.gemeente.address.street" , "irma-demo.gemeente.address.houseNumber", { "type" : "irma-demo.gemeente.address.city", "value": "Arnhem" }  ]
            ],
            [
              [ "irma-demo.sidn-pbdf.email.email" , { "type" : "irma-demo.sidn-pbdf.email.domain" , "value" : "test.com"} ]
            ]
          ]
        }
      ''';
  await irmaBinding.repository.startTestSession(sessionRequest);

  // The e-mail address is missing (the one in the app has another domain):
  // the address is in place, the e-mail address an empty spot.
  await waitForRequest(tester);
  expect(findShareSlot(0), findsOneWidget);
  expectEmptySpot(1, "Demo Email address");
  expect(find.byKey(const Key("share_spot_wrong")), findsNothing);
  expectShareWaitsFor(tester, "Demo Email address");

  // The issuer adds an e-mail address with the wrong domain.
  await issueCredentials(tester, irmaBinding, {
    "irma-demo.sidn-pbdf.email.email": "test@demo.com",
    "irma-demo.sidn-pbdf.email.domain": "demo.com",
  });

  // The spot says so in place: what was added and what is needed.
  final wrong = find.byKey(const Key("share_spot_wrong"));
  await tester.waitFor(wrong);
  expect(findEmptySpot(1), findsOneWidget);
  expect(
    tester.widget<Text>(wrong).data,
    "You added demo.com, needed test.com. Tap to add it again.",
  );

  // Now the issuer adds the right one: it lands in its spot.
  await issueCredentials(tester, irmaBinding, {
    "irma-demo.sidn-pbdf.email.email": "test@test.com",
    "irma-demo.sidn-pbdf.email.domain": "test.com",
  });
  await expectAddedInPlace(tester, 1);
  expect(wrong, findsNothing);
  expect(find.byType(SessionRequestorHeader), findsOneWidget);

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
    attributes: [
      ("Email address", "test@test.com"),
      ("Email domain name", "test.com"),
    ],
    style: IrmaCardStyle.normal,
  );

  await tapShare(tester);
  await evaluateFeedback(tester);
}

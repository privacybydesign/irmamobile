import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/requestor/requestor_card.dart";
import "package:yivi_core/src/widgets/credential_card/models/credential_card_status.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
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
  expect(findEmptySpot(0), findsNothing);
  // The e-mail address in the app has another domain: its row says what is
  // in the app and what is asked.
  expect(findNotCounted(1), findsOneWidget);
  expect(
    find.descendant(
      of: findNotCounted(1),
      matching: find.textContaining("In your app:"),
    ),
    findsOneWidget,
  );
  expectShareWaitsFor(tester, "Demo Email address");

  // The issuer adds an e-mail address with the wrong domain.
  await issueCredentials(tester, irmaBinding, {
    "irma-demo.sidn-pbdf.email.email": "test@demo.com",
    "irma-demo.sidn-pbdf.email.domain": "demo.com",
  });

  // Still a card with another value: the row stays to do.
  await tester.pumpAndSettle();
  expect(findNotCounted(1), findsOneWidget);
  expect(
    find.descendant(
      of: findNotCounted(1),
      matching: find.textContaining("In your app:"),
    ),
    findsOneWidget,
  );

  // Now the issuer adds the right one: it lands in its spot.
  await issueCredentials(tester, irmaBinding, {
    "irma-demo.sidn-pbdf.email.email": "test@test.com",
    "irma-demo.sidn-pbdf.email.domain": "test.com",
  });
  await expectAddedInPlace(tester, 1);
  expect(findNotCounted(1), findsNothing);
  await toOverview(tester);
  expect(find.byType(RequestorCard), findsOneWidget);

  final cardsFinder = findCredentialCards();
  await openChangePage(tester);
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

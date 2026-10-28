import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/session_requestor_header.dart";
import "package:yivi_core/src/widgets/irma_card.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
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

  // The owned e-mail address has the wrong domain, so it is no option: the
  // request shows an empty spot for one that matches.
  await waitForRequest(tester);
  // The e-mail address in the app doesn't count: it shows in place, with
  // what they ask beside its domain.
  expect(findNotCounted(0), findsOneWidget);
  expectShareWaitsFor(tester, "Demo Email address");

  // The issuer adds an e-mail address with the wrong domain.
  await issueCredentials(tester, irmaBinding, {
    "irma-demo.sidn-pbdf.email.email": "test@demo.com",
    "irma-demo.sidn-pbdf.email.domain": "demo.com",
  });

  // Still the card that doesn't count, now the one just added.
  await tester.pumpAndSettle();
  expect(findNotCounted(0), findsOneWidget);
  expect(findEmptySpot(0), findsNothing);

  // Now the issuer adds the right one: it lands in its spot.
  await issueCredentials(tester, irmaBinding, {
    "irma-demo.sidn-pbdf.email.email": "test@sidn.nl",
    "irma-demo.sidn-pbdf.email.domain": "sidn.nl",
  });
  await expectAddedInPlace(tester, 0);
  expect(findNotCounted(0), findsNothing);
  expect(find.byType(RequestorCard), findsOneWidget);

  final cardsFinder = findCredentialCards();
  expect(cardsFinder, findsOneWidget);
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

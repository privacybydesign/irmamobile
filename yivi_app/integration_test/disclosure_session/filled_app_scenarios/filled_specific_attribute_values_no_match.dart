import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/session_requestor_header.dart";
import "package:yivi_core/src/widgets/irma_card.dart";

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

  // The owned e-mail address has the wrong domain, so it is no option: the
  // request shows an empty spot for one that matches.
  await waitForRequest(tester);
  expectEmptySpot(0, "Demo Email address");
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
  expect(findEmptySpot(0), findsOneWidget);
  expect(
    tester.widget<Text>(wrong).data,
    "You added demo.com, needed sidn.nl. Tap to add it again.",
  );

  // Now the issuer adds the right one: it lands in its spot.
  await issueCredentials(tester, irmaBinding, {
    "irma-demo.sidn-pbdf.email.email": "test@sidn.nl",
    "irma-demo.sidn-pbdf.email.domain": "sidn.nl",
  });
  await expectAddedInPlace(tester, 0);
  expect(wrong, findsNothing);
  expect(find.byType(SessionRequestorHeader), findsOneWidget);

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

import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/disclosure/disclosure_flow.dart";
import "package:yivi_core/src/screens/session/disclosure/signed_message.dart";
import "package:yivi_core/src/screens/session/requestor/requestor_card.dart";
import "package:yivi_core/src/widgets/credential_card/models/credential_card_status.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../disclosure_helpers.dart";

Future<void> signingTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(tester, irmaBinding);

  // Email address
  // And signing the message: "Message to be signed by user"
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/signature/v2",
          "message": "Message to be signed by user",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email" ]
            ]
          ]
        }
      ''';
  await irmaBinding.repository.startTestSession(sessionRequest);
  await waitForRequest(tester);

  expect(find.byType(DisclosureFlow, skipOffstage: false), findsOneWidget);

  final requestorHeaderFinder = find.byType(RequestorCard);
  await evaluateRequestorHeader(
    tester,
    requestorHeaderFinder,
    localizedRequestorName: "is.demo.staging.yivi.app",
    isVerified: false,
  );

  expect(find.text("YOU SIGN WITH"), findsOneWidget);
  final quoteFinder = find.byType(SignedMessage);
  expect(quoteFinder, findsOneWidget);
  expect(
    tester.widget<SignedMessage>(quoteFinder).message,
    "Message to be signed by user",
  );

  await toOverview(tester);

  expect(find.byType(RequestorCard), findsOneWidget);

  final cardsFinder = findCredentialCards();
  await openChangePage(tester);
  expect(cardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: "Demo Email address",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: [("Email address", "test@example.com")],
    style: IrmaCardStyle.normal,
  );

  await tapShare(tester);
  await evaluateFeedback(tester, isSignatureSession: true);
}

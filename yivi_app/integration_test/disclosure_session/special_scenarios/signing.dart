import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
import "package:yivi_core/src/screens/session/widgets/session_requestor_header.dart";
import "package:yivi_core/src/widgets/irma_card.dart";
import "package:yivi_core/src/widgets/irma_quote.dart";

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

  expect(find.byType(DisclosureShareScreen), findsOneWidget);

  final requestorHeaderFinder = find.byType(RequestorCard);
  await evaluateRequestorHeader(
    tester,
    requestorHeaderFinder,
    localizedRequestorName: "is.demo.staging.yivi.app",
    isVerified: false,
  );

  expect(find.text("YOU SIGN"), findsOneWidget);
  final quoteFinder = find.byKey(const Key("signature_message"));
  expect(quoteFinder, findsOneWidget);
  expect(
    (quoteFinder.evaluate().first.widget as IrmaQuote).quote,
    "Message to be signed by user",
  );

  expect(find.byType(RequestorCard), findsOneWidget);

  final cardsFinder = findCredentialCards();
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

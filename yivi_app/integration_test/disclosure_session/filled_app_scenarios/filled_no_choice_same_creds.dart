import "package:flutter_test/flutter_test.dart";

import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";
import "sheet_checks.dart";

Future<void> filledNoChoiceSameCredsTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Issue two different email addresses
  await issueCredentials(tester, irmaBinding, {
    "irma-demo.sidn-pbdf.email.email": "first-email@example.com",
    "irma-demo.sidn-pbdf.email.domain": "example.com",
  });

  await issueCredentials(tester, irmaBinding, {
    "irma-demo.sidn-pbdf.email.email": "second-email@example.com",
    "irma-demo.sidn-pbdf.email.domain": "example.com",
  });

  // Session requesting:
  // Only email
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email" ]
            ]
          ]
        }
      ''';

  // Start session without the credential being present
  await irmaBinding.repository.startTestSession(sessionRequest);

  // The share screen starts with the first e-mail address.
  await tester.waitFor(find.byType(DisclosureShareScreen));
  final credentialCardsFinder = findCredentialCards();
  const demoEmailCredentialName = "Demo Email address";
  const demoEmailIssuerName = "Demo Privacy by Design Foundation via SIDN";
  expect(credentialCardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    credentialCardsFinder.first,
    credentialName: demoEmailCredentialName,
    issuerName: demoEmailIssuerName,
    attributes: [("Email address", "first-email@example.com")],
  );

  // Change it: both addresses are in the app, told apart by their value.
  await changeChoice(tester, 0);
  expectSheet(
    tester,
    owned: ["first-email@example.com", "second-email@example.com"],
    selected: "first-email@example.com",
  );

  // Pick the second one: the sheet closes.
  await pickOwned(tester, "second-email@example.com");

  // The only card on the share screen is now the second address.
  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  expect(credentialCardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    credentialCardsFinder.first,
    credentialName: demoEmailCredentialName,
    issuerName: demoEmailIssuerName,
    attributes: [("Email address", "second-email@example.com")],
  );

  // Finish the flow
  await tapShare(tester);
  await evaluateFeedback(tester);
}

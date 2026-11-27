import "package:flutter_test/flutter_test.dart";

import "package:yivi_core/src/screens/session/disclosure/disclosure_flow.dart";

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

  // The share screen starts with one of the two addresses (both issued
  // this week: irmago's order does not tell them apart).
  await tester.waitFor(find.byType(DisclosureFlow, skipOffstage: false));
  final credentialCardsFinder = findCredentialCards();
  const demoEmailCredentialName = "Demo Email address";
  const demoEmailIssuerName = "Demo Privacy by Design Foundation via SIDN";
  const emails = ["first-email@example.com", "second-email@example.com"];
  final first = await shownOf(tester, emails);
  final other = emails.firstWhere((e) => e != first);
  expect(credentialCardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    credentialCardsFinder.first,
    credentialName: demoEmailCredentialName,
    issuerName: demoEmailIssuerName,
    attributes: [("Email address", first)],
  );

  // Change it: both addresses are in the app, told apart by their value.
  await changeChoice(tester, 0);
  expectSheet(tester, owned: emails, selected: first);

  // Pick the other one: the sheet closes.
  await pickOwned(tester, other);

  // The only card on the share screen is now the other address.
  expect(find.byType(DisclosureFlow, skipOffstage: false), findsOneWidget);
  await openChangePage(tester);
  expect(credentialCardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    credentialCardsFinder.first,
    credentialName: demoEmailCredentialName,
    issuerName: demoEmailIssuerName,
    attributes: [("Email address", other)],
  );

  // Finish the flow
  await tapShare(tester);
  await evaluateFeedback(tester);
}

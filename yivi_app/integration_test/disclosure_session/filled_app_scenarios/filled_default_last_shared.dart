import "package:flutter_test/flutter_test.dart";

import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

/// The card a request starts on is the one last shared with this requestor,
/// from the activity log (#657): with two e-mail addresses in the app, a
/// request starts on the first, then on whichever was shared last time.
Future<void> filledDefaultLastSharedTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  await issueCredentials(tester, irmaBinding, {
    "irma-demo.sidn-pbdf.email.email": "first-email@example.com",
    "irma-demo.sidn-pbdf.email.domain": "example.com",
  });
  await issueCredentials(tester, irmaBinding, {
    "irma-demo.sidn-pbdf.email.email": "second-email@example.com",
    "irma-demo.sidn-pbdf.email.domain": "example.com",
  });

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

  /// Starts the request and checks the card it starts on.
  Future<void> startsOn(String email) async {
    await irmaBinding.repository.startTestSession(sessionRequest);
    await tester.waitFor(find.byType(DisclosureShareScreen));
    // The activity is looked up as the screen opens.
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    final cards = findCredentialCards();
    expect(cards, findsOneWidget);
    await evaluateCredentialCard(
      tester,
      cards.first,
      credentialName: "Demo Email address",
      issuerName: "Demo Privacy by Design Foundation via SIDN",
      attributes: [("Email address", email)],
    );
  }

  // Nothing shared yet: the first address.
  await startsOn("first-email@example.com");
  await changeChoice(tester, 0);
  await pickOwned(tester, "second-email@example.com");
  await tapShare(tester);
  await evaluateFeedback(tester);

  // The second was shared with this requestor last time: it starts on it.
  await startsOn("second-email@example.com");
  await changeChoice(tester, 0);
  await pickOwned(tester, "first-email@example.com");
  await tapShare(tester);
  await evaluateFeedback(tester);

  // And back to the first, which was shared last.
  await startsOn("first-email@example.com");
  await tapShare(tester);
  await evaluateFeedback(tester);
}

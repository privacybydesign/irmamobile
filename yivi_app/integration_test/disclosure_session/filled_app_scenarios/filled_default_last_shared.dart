import "package:flutter_test/flutter_test.dart";

import "package:yivi_core/src/screens/session/disclosure/disclosure_flow.dart";

import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

/// The card a request starts on is the one last shared with this requestor,
/// from the activity log (#657): with two e-mail addresses in the app, a
/// request starts on one (irmago cannot order two cards issued in the same
/// week), then on whichever was shared last time.
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
    await tester.waitFor(find.byType(DisclosureFlow));
    // The activity is looked up as the screen opens.
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    final cards = findCredentialCards();
    await openChangePage(tester);
    expect(cards, findsOneWidget);
    await evaluateCredentialCard(
      tester,
      cards.first,
      credentialName: "Demo Email address",
      issuerName: "Demo Privacy by Design Foundation via SIDN",
      attributes: [("Email address", email)],
    );
  }

  const emails = ["first-email@example.com", "second-email@example.com"];

  // Nothing shared yet: one of the two; share the other.
  await irmaBinding.repository.startTestSession(sessionRequest);
  await tester.waitFor(find.byType(DisclosureFlow));
  final first = await shownOf(tester, emails);
  final other = emails.firstWhere((e) => e != first);
  await changeChoice(tester, 0);
  await pickOwned(tester, other);
  await tapShare(tester);
  await evaluateFeedback(tester);

  // That one was shared with this requestor last time: it starts on it.
  await startsOn(other);
  await changeChoice(tester, 0);
  await pickOwned(tester, first);
  await tapShare(tester);
  await evaluateFeedback(tester);

  // And back to the first, which was shared last.
  await startsOn(first);
  await tapShare(tester);
  await evaluateFeedback(tester);
}

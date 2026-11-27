import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/notifications/widgets/notification_card.dart";
import "package:yivi_core/src/screens/session/disclosure/disclosure_flow.dart";
import "package:yivi_core/src/widgets/buttons/close_button.dart";

import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

Future<void> _evaluateDemoCredentialCard(
  WidgetTester tester,
  Finder revokedCardFinder, {
  required bool isRevoked,
}) => evaluateCredentialCard(
  tester,
  revokedCardFinder,
  credentialName: "Demo Root",
  issuerName: "Demo MijnOverheid.nl",
  attributes: [("BSN", "12345")],
  isRevoked: isRevoked,
);

Future<void> revocationTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Make sure a revoked credential is present
  final revocationKey = generateRevocationKey();
  await issueCredentials(
    tester,
    irmaBinding,
    {"irma-demo.MijnOverheid.root.BSN": "12345"},
    revocationKeys: {"irma-demo.MijnOverheid.root": revocationKey},
  );

  // Close the add credential success screen
  await tester.tap(find.text("OK"));

  await revokeCredential("irma-demo.MijnOverheid.root", revocationKey);
  await irmaBinding.repository.startTestSession('''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.MijnOverheid.root.BSN" ]
            ]
          ],
          "revocation": [ "irma-demo.MijnOverheid.root" ]
        }
      ''');
  await waitForRequest(tester);

  // The card is revoked and a non-revocation proof is asked: the add step,
  // to add it again (2.10).
  expect(find.byType(DisclosureFlow), findsOneWidget);
  expect(
    find.descendant(
      of: findEmptySpot(0),
      matching: find.text("Revoked. Add it again."),
    ),
    findsOneWidget,
  );

  // Close the session
  await tester.tapAndSettle(find.byType(YiviCloseButton));

  // Confirm the close dialog
  await tester.tapAndSettle(find.text("Yes"));

  // The notifications tab button should be findable in the tab bar
  final notificationsTabFinder = find.byKey(
    const Key("nav_button_notifications"),
  );
  expect(notificationsTabFinder, findsOneWidget);
  await tester.tapAndSettle(notificationsTabFinder);

  // Now pull to refresh and expect a notification card
  await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
  await tester.pumpAndSettle();

  final notificationCardsFinder = find.byType(NotificationCard);
  expect(notificationCardsFinder, findsOneWidget);

  final notificationCardFinder = notificationCardsFinder.first;
  await evaluateNotificationCard(
    tester,
    notificationCardFinder,
    title: "Data revoked",
    content: "Demo MijnOverheid.nl has revoked this data: Demo Root",
    read: false,
  );

  // Tap the notification card to open the credential detail screen. The card
  // is still in the wallet, so this is the card's detail view.
  await tester.tapAndSettle(notificationCardFinder);
  final credentialDetailFinder = findCredentialDetail();
  expect(credentialDetailFinder, findsOneWidget);

  // The detail view shows the revoked card (Revoked chip, Reobtain button).
  await evaluateCredentialCard(
    tester,
    credentialDetailFinder,
    credentialName: "Demo Root",
    issuerName: "Demo MijnOverheid.nl",
    attributes: [("BSN", "12345")],
    isRevoked: true,
  );

  // The card's actions are on the detail view itself now (the old options
  // bottom sheet is gone): the revoked card can still be deleted.
  expect(
    find.descendant(
      of: credentialDetailFinder,
      matching: find.byKey(const Key("credential_detail_delete")),
    ),
    findsOneWidget,
  );

  // Close the detail view
  await closeCredentialDetail(tester);

  // Start the disclosure session again, again asking for a non-revocation
  // proof: only then is a revoked card unusable (irmago decides, 2.14)
  await irmaBinding.repository.startTestSession('''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.MijnOverheid.root.BSN" ]
            ]
          ],
          "revocation": [ "irma-demo.MijnOverheid.root" ]
        }
      ''');

  // Introduction was already completed in the first session, so it's skipped.
  await tester.waitFor(find.byType(DisclosureFlow));
  expect(find.byType(DisclosureFlow), findsOneWidget);

  // The revoked card cannot be shared: the add step shows it, to add again
  // (2.10), and nothing can be shared yet.
  expect(findEmptySpot(0), findsOneWidget);
  expect(
    find.descendant(
      of: findEmptySpot(0),
      matching: find.text("Revoked. Add it again."),
    ),
    findsOneWidget,
  );
  expectShareWaitsFor(tester, "Demo Root");
  expect(shareButtonEnabled(tester), isFalse);

  // Now reobtain the card.
  await issueCredentials(
    tester,
    irmaBinding,
    {"irma-demo.MijnOverheid.root.BSN": "12345"},
    revocationKeys: {"irma-demo.MijnOverheid.root": generateRevocationKey()},
  );

  // The new card is in, and it is the one shared.
  await expectAddedInPlace(tester, 0);
  expect(shareButtonEnabled(tester), isTrue);
  await toOverview(tester);
  await _evaluateDemoCredentialCard(
    tester,
    findCredentialCards().first,
    isRevoked: false,
  );

  await tapShare(tester);
  await evaluateFeedback(tester);
}

import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/notifications/widgets/notification_card.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
import "package:yivi_core/src/screens/session/widgets/session_requestor_header.dart";
import "package:yivi_core/src/widgets/irma_close_button.dart";

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

  // The disclosure permission overview screen should be visible.
  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  expect(find.textContaining("is asking for your data"), findsOneWidget);
  expect(find.byType(RequestorCard), findsOneWidget);

  // Find all credential cards
  final cardsFinder = findCredentialCards();
  expect(cardsFinder, findsOneWidget);

  // Close the session
  await tester.tapAndSettle(find.byType(IrmaCloseButton));

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

  // Start the disclosure session again
  await irmaBinding.repository.startTestSession('''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.MijnOverheid.root.BSN" ]
            ]
          ]
        }
      ''');

  // Introduction was already completed in the first session, so it's skipped.
  await tester.waitFor(find.byType(DisclosureShareScreen));
  expect(find.byType(DisclosureShareScreen), findsOneWidget);

  // Find the revoked credential card and evaluate it
  final demoCredentialCardFinder = cardsFinder.first;
  await _evaluateDemoCredentialCard(
    tester,
    demoCredentialCardFinder,
    isRevoked: true,
  );

  // The button doesn't share: it gets a new card (or, without a way to in
  // Yivi, closes), with what is left above it. The card itself has no
  // button.
  expect(shareButtonEnabled(tester), isFalse);
  expect(
    shareReason(tester),
    anyOf(
      "One more thing to sort out, then you can share",
      contains("can't renew"),
    ),
  );
  expect(find.byKey(const Key("shared_card_fix")), findsNothing);

  expect(find.byKey(const Key("share_change_0")), findsNothing);

  // Now reobtain the card.
  await issueCredentials(
    tester,
    irmaBinding,
    {"irma-demo.MijnOverheid.root.BSN": "12345"},
    revocationKeys: {"irma-demo.MijnOverheid.root": generateRevocationKey()},
  );

  // Revoked card should be visible here too.
  await _evaluateDemoCredentialCard(
    tester,
    demoCredentialCardFinder,
    isRevoked: false,
  );

  // The share button is enabled now.
  expect(shareButtonEnabled(tester), isTrue);

  await tapShare(tester);
  await evaluateFeedback(tester);
}

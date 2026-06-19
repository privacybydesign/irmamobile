import "package:flutter/material.dart";
// ignore: depend_on_referenced_packages
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../../screens/data/data_tab.dart";
import "../../screens/data/schemaless_credentials_details_screen.dart";
import "../../screens/notifications/bloc/notifications_bloc.dart";
import "../../screens/notifications/notifications_tab.dart";
import "../../screens/notifications/widgets/notification_bell.dart";
import "../../screens/notifications/widgets/notification_card.dart";
import "../../screens/session/widgets/disclosure_choices_overview.dart";
import "../../screens/session/widgets/issuance_permission.dart";
import "../../screens/session/widgets/issuance_success_screen.dart";
import "../../widgets/credential_card/delete_credential_confirmation_dialog.dart";
import "../../widgets/credential_card/yivi_credential_card.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_close_button.dart";
import "../helpers/helpers.dart";
import "../helpers/openid4vci_helpers.dart";
import "../irma_binding.dart";
import "../util.dart";
import "disclosure_session/disclosure_helpers.dart";

const _revokableCredId = "irma-demo.MijnOverheid.root";
const _revokableCredAttribute = "$_revokableCredId.BSN";
const _revokedRevokedTitle = "Data revoked";
const _revokedRevokedContent =
    "Demo MijnOverheid.nl has revoked this data: Demo Root";
const _expiringSoonTitle = "Data expiring soon";
const _expiringSoonContent =
    "This data is expiring soon: Email Credential (SD-JWT)";
const _expiredTitle = "Data expired";
const _expiredContent = "This data has expired: Email Credential (SD-JWT)";

final _notificationsScreenFinder = find.byType(NotificationsTab);
final _notificationBellFinder = find.byType(NotificationBell);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("notifications", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets("reach", (tester) => testReach(tester, irmaBinding));

    testWidgets("empty-state", (tester) => testEmptyState(tester, irmaBinding));

    testWidgets(
      "filled-state",
      (tester) => testFilledState(tester, irmaBinding),
    );

    testWidgets(
      "read-all-notifications",
      (tester) => testReadAllNotifications(tester, irmaBinding),
    );

    testWidgets(
      "dismiss-notification",
      (tester) => testDismissNotification(tester, irmaBinding),
    );

    testWidgets(
      "notification-action",
      (tester) => testNotificationAction(tester, irmaBinding),
    );

    testWidgets(
      "multiple-notifications-and-per-card-navigation",
      (tester) =>
          testMultipleNotificationsAndPerCardNavigation(tester, irmaBinding),
    );

    testWidgets(
      "orphan-record-cleanup-on-credential-delete",
      (tester) =>
          testOrphanRecordCleanupOnCredentialDelete(tester, irmaBinding),
    );

    testWidgets(
      "lifecycle-resume-triggers-load-notifications",
      (tester) =>
          testLifecycleResumeTriggersLoadNotifications(tester, irmaBinding),
    );

    testWidgets(
      "cold-start-persists-dismissed-flag",
      (tester) => testColdStartPersistsDismissedFlag(tester, irmaBinding),
    );

    testWidgets(
      "type-transition-expiringSoon-to-expired",
      (tester) => testTypeTransitionExpiringSoonToExpired(tester, irmaBinding),
    );

    testWidgets(
      "re-issue-clears-revoked-notification",
      (tester) => testReIssueClearsRevokedNotification(tester, irmaBinding),
    );

    testWidgets(
      "expired-credential-shows-expiration-notification",
      (tester) =>
          testExpiredCredentialShowsExpirationNotification(tester, irmaBinding),
    );
  });
}

// =============================================================================
// Helpers
// =============================================================================

/// Issues a revocable demo credential, revokes it server-side, then runs a
/// disclosure session that performs the revocation check so the local cred
/// state reflects the revocation. Leaves the user back on the home screen.
Future<void> _issueAndRevokeDemoCredential(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  final revocationKey = generateRevocationKey();
  await issueCredentials(
    tester,
    irmaBinding,
    {_revokableCredAttribute: "12345"},
    revocationKeys: {_revokableCredId: revocationKey},
  );
  await tester.tap(find.text("OK"));
  await revokeCredential(_revokableCredId, revocationKey);

  // A disclosure session including a revocation check is what surfaces the
  // revoked status to the local credential store.
  await irmaBinding.repository.startTestSession('''
    {
      "@context": "https://irma.app/ld/request/disclosure/v2",
      "disclose": [
        [
          [ "$_revokableCredAttribute" ]
        ]
      ],
      "revocation": [ "$_revokableCredId" ]
    }
  ''');

  await evaluateIntroduction(tester);
  await tester.waitFor(find.byType(DisclosureChoicesOverview));

  await tester.tapAndSettle(find.byType(IrmaCloseButton));
  await tester.tapAndSettle(find.text("Yes"));
}

/// Issues an OID4VCI SD-JWT email credential with the given TTL via the
/// pre-authorized code flow. Walks through `IssuancePermission` →
/// `IssuanceSuccessScreen` → "OK". Returns the timestamp captured just before
/// the offer call so callers can compute when the credential expires.
Future<DateTime> _issueOid4vciEmailCredential(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  required int ttlSeconds,
}) async {
  final issuedAt = DateTime.now();
  final offer = await startOpenID4VCISession(
    credentialConfigId: "EmailCredentialSdJwt",
    credentialData: {"email": "test@example.com", "domain": "example.com"},
    ttlSeconds: ttlSeconds,
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  await tester.waitFor(find.byType(IssuancePermission));
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

  await tester.waitFor(find.byType(IssuanceSuccessScreen));
  await tester.tapAndSettle(find.text("OK"));
  return issuedAt;
}

Finder _cardWithContent(String content) => find.ancestor(
  of: find.text(content),
  matching: find.byType(NotificationCard),
);

// =============================================================================
// Test bodies
// =============================================================================

Future<void> testReach(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  expect(_notificationBellFinder, findsOneWidget);

  await tester.tapAndSettle(find.byKey(const Key("nav_button_activity")));
  expect(_notificationBellFinder, findsOneWidget);

  await tester.tapAndSettle(find.byKey(const Key("nav_button_more")));
  expect(_notificationBellFinder, findsOneWidget);

  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await tester.tapAndSettle(_notificationBellFinder);
  expect(_notificationsScreenFinder, findsOneWidget);
}

Future<void> testEmptyState(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  await tester.tapAndSettle(_notificationBellFinder);
  expect(_notificationsScreenFinder, findsOneWidget);

  final screenTitleFinder = find.descendant(
    of: find.byType(IrmaAppBar),
    matching: find.text("Notifications"),
  );
  expect(screenTitleFinder, findsOneWidget);

  final emptyStateMessageFinder = find.descendant(
    of: _notificationsScreenFinder,
    matching: find.text("No notifications"),
  );
  expect(emptyStateMessageFinder, findsOneWidget);
}

Future<void> testFilledState(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await _issueAndRevokeDemoCredential(tester, irmaBinding);

  await tester.tapAndSettle(_notificationBellFinder);
  expect(_notificationsScreenFinder, findsOneWidget);

  await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
  await tester.pumpAndSettle();

  final notificationCardFinder = find.byType(NotificationCard);
  expect(notificationCardFinder, findsOneWidget);

  await evaluateNotificationCard(
    tester,
    notificationCardFinder,
    title: _revokedRevokedTitle,
    content: _revokedRevokedContent,
  );
}

Future<void> testReadAllNotifications(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await _issueAndRevokeDemoCredential(tester, irmaBinding);

  await tester.tapAndSettle(_notificationBellFinder);
  expect(_notificationsScreenFinder, findsOneWidget);

  await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
  await tester.pumpAndSettle();

  // Bell should still indicate unread (we haven't left the tab yet).
  expect(
    tester.widget<NotificationBell>(_notificationBellFinder).showIndicator,
    true,
  );

  final notificationCardFinder = find.byType(NotificationCard);
  expect(notificationCardFinder, findsOneWidget);
  await evaluateNotificationCard(
    tester,
    notificationCardFinder,
    title: _revokedRevokedTitle,
    content: _revokedRevokedContent,
    read: false,
  );

  // Leaving the tab fires MarkAllNotificationsAsRead in dispose.
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await tester.pumpAndSettle();

  expect(
    tester.widget<NotificationBell>(_notificationBellFinder).showIndicator,
    false,
  );

  await tester.tapAndSettle(_notificationBellFinder);
  expect(_notificationsScreenFinder, findsOneWidget);

  final notificationCardFinder2 = find.byType(NotificationCard);
  expect(notificationCardFinder2, findsOneWidget);
  await evaluateNotificationCard(
    tester,
    notificationCardFinder2,
    title: _revokedRevokedTitle,
    content: _revokedRevokedContent,
    read: true,
  );
}

Future<void> testDismissNotification(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await _issueAndRevokeDemoCredential(tester, irmaBinding);

  await tester.tapAndSettle(_notificationBellFinder);
  expect(_notificationsScreenFinder, findsOneWidget);

  await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
  await tester.pumpAndSettle();

  final notificationCardFinder = find.byType(NotificationCard);
  expect(notificationCardFinder, findsOneWidget);

  await tester.drag(notificationCardFinder, const Offset(-500, 0));
  await tester.pumpAndSettle();
  expect(notificationCardFinder, findsNothing);

  // Navigate away and back; dismissal must persist.
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await tester.tapAndSettle(_notificationBellFinder);
  expect(notificationCardFinder, findsNothing);

  // A fresh LoadNotifications must respect the dismissed flag.
  await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
  await tester.pumpAndSettle();
  expect(notificationCardFinder, findsNothing);
}

Future<void> testNotificationAction(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await _issueAndRevokeDemoCredential(tester, irmaBinding);

  await tester.tapAndSettle(_notificationBellFinder);
  expect(_notificationsScreenFinder, findsOneWidget);

  await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
  await tester.pumpAndSettle();

  final notificationCardFinder = find.byType(NotificationCard);
  expect(notificationCardFinder, findsOneWidget);
  await evaluateNotificationCard(
    tester,
    notificationCardFinder,
    title: _revokedRevokedTitle,
    content: _revokedRevokedContent,
    read: false,
  );

  await tester.tapAndSettle(notificationCardFinder);

  expect(find.byType(SchemalessCredentialsDetailsScreen), findsOneWidget);
  final credentialCardFinder = find.byType(YiviCredentialCard);
  await evaluateCredentialCard(
    tester,
    credentialCardFinder.first,
    credentialName: "Demo Root",
    issuerName: "Demo MijnOverheid.nl",
    attributes: [("BSN", "12345")],
    isRevoked: true,
  );

  await tester.tapAndSettle(find.byKey(const Key("irma_app_bar_leading")));
  expect(_notificationsScreenFinder, findsOneWidget);

  final notificationCardFinder2 = find.byType(NotificationCard);
  expect(notificationCardFinder2, findsOneWidget);
  await evaluateNotificationCard(
    tester,
    notificationCardFinder2,
    title: _revokedRevokedTitle,
    content: _revokedRevokedContent,
    read: true,
  );
}

Future<void> testMultipleNotificationsAndPerCardNavigation(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await _issueAndRevokeDemoCredential(tester, irmaBinding);
  // 3-day TTL puts the SD-JWT cred squarely in the expiringSoon window
  // (validDays <= 7) without needing to wait for it to expire.
  await _issueOid4vciEmailCredential(
    tester,
    irmaBinding,
    ttlSeconds: 86400 * 3,
  );

  await tester.tapAndSettle(_notificationBellFinder);
  expect(_notificationsScreenFinder, findsOneWidget);

  await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
  await tester.pumpAndSettle();

  expect(find.byType(NotificationCard), findsExactly(2));
  expect(_cardWithContent(_revokedRevokedContent), findsOneWidget);
  expect(_cardWithContent(_expiringSoonContent), findsOneWidget);

  await evaluateNotificationCard(
    tester,
    _cardWithContent(_revokedRevokedContent),
    title: _revokedRevokedTitle,
    read: false,
  );
  await evaluateNotificationCard(
    tester,
    _cardWithContent(_expiringSoonContent),
    title: _expiringSoonTitle,
    read: false,
  );

  // Tap the revoked card → MijnOverheid.root details. Back.
  await tester.tapAndSettle(_cardWithContent(_revokedRevokedContent));
  expect(find.byType(SchemalessCredentialsDetailsScreen), findsOneWidget);
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard).first,
    credentialName: "Demo Root",
  );
  await tester.tapAndSettle(find.byKey(const Key("irma_app_bar_leading")));
  expect(_notificationsScreenFinder, findsOneWidget);

  // Revoked card now read; expiring card still unread; bell still on.
  await evaluateNotificationCard(
    tester,
    _cardWithContent(_revokedRevokedContent),
    read: true,
  );
  await evaluateNotificationCard(
    tester,
    _cardWithContent(_expiringSoonContent),
    read: false,
  );
  expect(
    tester.widget<NotificationBell>(_notificationBellFinder).showIndicator,
    true,
  );

  // Tap the expiring card → SD-JWT email details. Back.
  await tester.tapAndSettle(_cardWithContent(_expiringSoonContent));
  expect(find.byType(SchemalessCredentialsDetailsScreen), findsOneWidget);
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard).first,
    credentialName: "Email Credential (SD-JWT)",
  );
  await tester.tapAndSettle(find.byKey(const Key("irma_app_bar_leading")));
  expect(_notificationsScreenFinder, findsOneWidget);

  // Both cards read now.
  await evaluateNotificationCard(
    tester,
    _cardWithContent(_revokedRevokedContent),
    read: true,
  );
  await evaluateNotificationCard(
    tester,
    _cardWithContent(_expiringSoonContent),
    read: true,
  );

  // Leave the tab once more; bell indicator should be off now.
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await tester.pumpAndSettle();
  expect(
    tester.widget<NotificationBell>(_notificationBellFinder).showIndicator,
    false,
  );
}

Future<void> testOrphanRecordCleanupOnCredentialDelete(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await _issueAndRevokeDemoCredential(tester, irmaBinding);

  await tester.tapAndSettle(_notificationBellFinder);
  await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
  await tester.pumpAndSettle();
  expect(find.byType(NotificationCard), findsOneWidget);

  // Delete the credential from the data tab.
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await navigateToCredentialDetailsPage(tester, _revokableCredId);

  final credentialCardFinder = find.byType(YiviCredentialCard).first;
  await tester.tapAndSettle(
    find.descendant(
      of: credentialCardFinder,
      matching: find.byIcon(Icons.more_horiz_sharp),
    ),
  );
  await tester.tapAndSettle(find.text("Delete data"));
  expect(find.byType(DeleteCredentialConfirmationDialog), findsOneWidget);
  await tester.tapAndSettle(find.text("Delete"));

  // After deleting the last instance, the screen pops back to DataTab.
  await tester.waitFor(find.byType(DataTab));
  // Wait for the post-delete snackbar to disappear so it doesn't overlap
  // the RefreshIndicator hit area on the notifications tab.
  await tester.pumpAndSettle(const Duration(seconds: 5));

  // Open notifications and refresh — the orphan record must be dropped.
  await tester.tapAndSettle(_notificationBellFinder);
  await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
  await tester.pumpAndSettle();
  expect(find.byType(NotificationCard), findsNothing);
}

Future<void> testLifecycleResumeTriggersLoadNotifications(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await _issueAndRevokeDemoCredential(tester, irmaBinding);

  // Pre-condition: Initialize ran with 0 creds before issuance, and no event
  // has retriggered LoadNotifications since. Bell is off.
  expect(
    tester.widget<NotificationBell>(_notificationBellFinder).showIndicator,
    false,
  );

  // Drive the lifecycle observer in app.dart that calls
  // notificationsBloc.add(LoadNotifications()) on resume.
  WidgetsBinding.instance.handleAppLifecycleStateChanged(
    AppLifecycleState.resumed,
  );
  await tester.pumpAndSettle();

  expect(
    tester.widget<NotificationBell>(_notificationBellFinder).showIndicator,
    true,
  );

  await tester.tapAndSettle(_notificationBellFinder);
  expect(_notificationsScreenFinder, findsOneWidget);
  final notificationCardFinder = find.byType(NotificationCard);
  expect(notificationCardFinder, findsOneWidget);
  await evaluateNotificationCard(
    tester,
    notificationCardFinder,
    title: _revokedRevokedTitle,
    content: _revokedRevokedContent,
    read: false,
  );
}

Future<void> testColdStartPersistsDismissedFlag(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await _issueAndRevokeDemoCredential(tester, irmaBinding);

  await tester.tapAndSettle(_notificationBellFinder);
  await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
  await tester.pumpAndSettle();

  final notificationCardFinder = find.byType(NotificationCard);
  expect(notificationCardFinder, findsOneWidget);

  // Dismiss within session.
  await tester.drag(notificationCardFinder, const Offset(-500, 0));
  await tester.pumpAndSettle();
  expect(notificationCardFinder, findsNothing);

  // Drive a fresh Initialize to exercise the same cold-start code path the
  // bloc takes on real app launch: read serialized records from prefs, run
  // each handler against the live credential store, derive runtime
  // notifications, and yield NotificationsInitialized. The dismissed flag
  // must survive the JSON round-trip.
  final bloc = BlocProvider.of<NotificationsBloc>(
    tester.element(find.byType(NotificationsTab)),
  );
  bloc.add(Initialize());
  await tester.pumpAndSettle();

  expect(find.byType(NotificationCard), findsNothing);
}

Future<void> testTypeTransitionExpiringSoonToExpired(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // 30s gives ~25s headroom for issuance + first refresh while still expiring
  // within a tractable test runtime.
  const ttlSeconds = 30;
  final issuedAt = await _issueOid4vciEmailCredential(
    tester,
    irmaBinding,
    ttlSeconds: ttlSeconds,
  );

  await tester.tapAndSettle(_notificationBellFinder);
  await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
  await tester.pumpAndSettle();

  final expiringCardFinder = find.byType(NotificationCard);
  expect(expiringCardFinder, findsOneWidget);
  await evaluateNotificationCard(
    tester,
    expiringCardFinder,
    title: _expiringSoonTitle,
    content: _expiringSoonContent,
    read: false,
  );

  // Leave the tab → MarkAllNotificationsAsRead fires; the existing
  // (hash, expiringSoon) record now has read=true.
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await tester.pumpAndSettle();

  // Wait until the credential's exp has passed. The 10s safety margin covers
  // clock skew between client and Veramo issuer plus HTTP latency on the
  // create-offer call (server-side `exp = serverNow + ttl` can be a few
  // seconds ahead of `issuedAt`, so a tight buffer can leave the cred still
  // valid by the handler's clock check).
  final expiresAt = issuedAt.add(const Duration(seconds: ttlSeconds));
  final remaining =
      expiresAt.difference(DateTime.now()) + const Duration(seconds: 10);
  if (!remaining.isNegative) {
    await Future.delayed(remaining);
  }

  await tester.tapAndSettle(_notificationBellFinder);
  await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
  await tester.pumpAndSettle();

  // The handler dropped the (hash, expiringSoon) record (no live cred matches
  // that type anymore) and minted a fresh (hash, expired) record with
  // read=false.
  final expiredCardFinder = find.byType(NotificationCard);
  expect(expiredCardFinder, findsOneWidget);
  await evaluateNotificationCard(
    tester,
    expiredCardFinder,
    title: _expiredTitle,
    content: _expiredContent,
    read: false,
  );
}

Future<void> testReIssueClearsRevokedNotification(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await _issueAndRevokeDemoCredential(tester, irmaBinding);

  await tester.tapAndSettle(_notificationBellFinder);
  await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
  await tester.pumpAndSettle();
  expect(find.byType(NotificationCard), findsOneWidget);

  // Re-issue with a fresh revocation key. The new cred is born non-revoked;
  // the old hash is replaced.
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await issueCredentials(
    tester,
    irmaBinding,
    {_revokableCredAttribute: "12345"},
    revocationKeys: {_revokableCredId: generateRevocationKey()},
  );
  await tester.tapAndSettle(find.text("OK"));

  await tester.tapAndSettle(_notificationBellFinder);
  await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
  await tester.pumpAndSettle();

  expect(find.byType(NotificationCard), findsNothing);
}

/// Issues an SD-JWT email credential with a short TTL via OpenID4VCI, waits
/// for it to expire, then verifies that the notifications tab surfaces a
/// "Data expired" notification for it and that tapping the notification opens
/// the credential detail screen.
Future<void> testExpiredCredentialShowsExpirationNotification(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Confirm a clean starting state so any card observed later is one we
  // caused.
  await tester.tapAndSettle(_notificationBellFinder);
  expect(_notificationsScreenFinder, findsOneWidget);
  expect(find.byType(NotificationCard), findsNothing);
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

  // Issue with a short positive TTL — issuance verifies the JWT's `exp`, so
  // it must still be in the future when the credential is fetched; we then
  // wait for it to expire before refreshing notifications.
  const ttlSeconds = 10;
  final issuedAt = await _issueOid4vciEmailCredential(
    tester,
    irmaBinding,
    ttlSeconds: ttlSeconds,
  );

  // Wait until the credential's exp has passed (with a safety margin large
  // enough to cover client/server clock skew + create-offer HTTP latency).
  final expiresAt = issuedAt.add(const Duration(seconds: ttlSeconds));
  final remaining =
      expiresAt.difference(DateTime.now()) + const Duration(seconds: 10);
  if (!remaining.isNegative) {
    await Future.delayed(remaining);
  }

  // Open the notifications tab and pull-to-refresh to drive the handler.
  await tester.tapAndSettle(_notificationBellFinder);
  expect(_notificationsScreenFinder, findsOneWidget);

  await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
  await tester.pumpAndSettle();

  final notificationCardFinder = find.byType(NotificationCard);
  expect(notificationCardFinder, findsOneWidget);
  await evaluateNotificationCard(
    tester,
    notificationCardFinder,
    title: _expiredTitle,
    content: _expiredContent,
    read: false,
  );

  // Tapping the notification opens the credential detail screen.
  await tester.tapAndSettle(notificationCardFinder);
  expect(find.byType(SchemalessCredentialsDetailsScreen), findsOneWidget);
}

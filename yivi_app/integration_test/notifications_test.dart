import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:yivi_core/src/screens/data/schemaless_credentials_details_screen.dart";
import "package:yivi_core/src/screens/notifications/notifications_tab.dart";
import "package:yivi_core/src/screens/notifications/widgets/notification_bell.dart";
import "package:yivi_core/src/screens/notifications/widgets/notification_card.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";
import "package:yivi_core/src/widgets/irma_app_bar.dart";
import "package:yivi_core/src/widgets/irma_close_button.dart";

import "disclosure_session/disclosure_helpers.dart";
import "helpers/helpers.dart";
import "irma_binding.dart";
import "util.dart";

const _revokableCredId = "irma-demo.MijnOverheid.root";
const _revokableCredAttribute = "$_revokableCredId.BSN";

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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("notifications", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    final notificationsScreenFinder = find.byType(NotificationsTab);
    final notificationBellFinder = find.byType(NotificationBell);

    testWidgets("reach", (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      expect(notificationBellFinder, findsOneWidget);

      await tester.tapAndSettle(find.byKey(const Key("nav_button_activity")));
      expect(notificationBellFinder, findsOneWidget);

      await tester.tapAndSettle(find.byKey(const Key("nav_button_more")));
      expect(notificationBellFinder, findsOneWidget);

      await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
      await tester.tapAndSettle(notificationBellFinder);
      expect(notificationsScreenFinder, findsOneWidget);
    });

    testWidgets("empty-state", (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);

      await tester.tapAndSettle(notificationBellFinder);
      expect(notificationsScreenFinder, findsOneWidget);

      final screenTitleFinder = find.descendant(
        of: find.byType(IrmaAppBar),
        matching: find.text("Notifications"),
      );
      expect(screenTitleFinder, findsOneWidget);

      final emptyStateMessageFinder = find.descendant(
        of: notificationsScreenFinder,
        matching: find.text("No notifications"),
      );
      expect(emptyStateMessageFinder, findsOneWidget);
    });

    testWidgets("filled-state", (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      await _issueAndRevokeDemoCredential(tester, irmaBinding);

      await tester.tapAndSettle(notificationBellFinder);
      expect(notificationsScreenFinder, findsOneWidget);

      // Pull-to-refresh to drive LoadNotifications and surface the revocation.
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
      await tester.pumpAndSettle();

      final notificationCardFinder = find.byType(NotificationCard);
      expect(notificationCardFinder, findsOneWidget);

      await evaluateNotificationCard(
        tester,
        notificationCardFinder,
        title: "Data revoked",
        content: "Demo MijnOverheid.nl has revoked this data: Demo Root",
      );
    });

    testWidgets("read-all-notifications", (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      await _issueAndRevokeDemoCredential(tester, irmaBinding);

      await tester.tapAndSettle(notificationBellFinder);
      expect(notificationsScreenFinder, findsOneWidget);

      // Pull-to-refresh to surface the revocation notification.
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
      await tester.pumpAndSettle();

      // Bell should still indicate unread (we haven't left the tab yet).
      final bellWhileOpen = tester.widget<NotificationBell>(
        notificationBellFinder,
      );
      expect(bellWhileOpen.showIndicator, true);

      final notificationCardFinder = find.byType(NotificationCard);
      expect(notificationCardFinder, findsOneWidget);
      await evaluateNotificationCard(
        tester,
        notificationCardFinder,
        title: "Data revoked",
        content: "Demo MijnOverheid.nl has revoked this data: Demo Root",
        read: false,
      );

      // Leaving the tab fires MarkAllNotificationsAsRead in dispose.
      await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
      await tester.pumpAndSettle();

      final bellAfterClose = tester.widget<NotificationBell>(
        notificationBellFinder,
      );
      expect(bellAfterClose.showIndicator, false);

      // Re-open and confirm the card is now marked read.
      await tester.tapAndSettle(notificationBellFinder);
      expect(notificationsScreenFinder, findsOneWidget);

      final notificationCardFinder2 = find.byType(NotificationCard);
      expect(notificationCardFinder2, findsOneWidget);
      await evaluateNotificationCard(
        tester,
        notificationCardFinder2,
        title: "Data revoked",
        content: "Demo MijnOverheid.nl has revoked this data: Demo Root",
        read: true,
      );
    });

    testWidgets("dismiss-notification", (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      await _issueAndRevokeDemoCredential(tester, irmaBinding);

      await tester.tapAndSettle(notificationBellFinder);
      expect(notificationsScreenFinder, findsOneWidget);

      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
      await tester.pumpAndSettle();

      final notificationCardFinder = find.byType(NotificationCard);
      expect(notificationCardFinder, findsOneWidget);

      await tester.drag(notificationCardFinder, const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(notificationCardFinder, findsNothing);

      // Navigate away and back; dismissal must persist.
      await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
      await tester.tapAndSettle(notificationBellFinder);
      expect(notificationCardFinder, findsNothing);

      // A fresh LoadNotifications must respect the dismissed flag.
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
      await tester.pumpAndSettle();
      expect(notificationCardFinder, findsNothing);
    });

    testWidgets("notification-action", (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      await _issueAndRevokeDemoCredential(tester, irmaBinding);

      await tester.tapAndSettle(notificationBellFinder);
      expect(notificationsScreenFinder, findsOneWidget);

      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
      await tester.pumpAndSettle();

      final notificationCardFinder = find.byType(NotificationCard);
      expect(notificationCardFinder, findsOneWidget);
      await evaluateNotificationCard(
        tester,
        notificationCardFinder,
        title: "Data revoked",
        content: "Demo MijnOverheid.nl has revoked this data: Demo Root",
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
      expect(notificationsScreenFinder, findsOneWidget);

      final notificationCardFinder2 = find.byType(NotificationCard);
      expect(notificationCardFinder2, findsOneWidget);
      await evaluateNotificationCard(
        tester,
        notificationCardFinder2,
        title: "Data revoked",
        content: "Demo MijnOverheid.nl has revoked this data: Demo Root",
        read: true,
      );
    });
  });
}

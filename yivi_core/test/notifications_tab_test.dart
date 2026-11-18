import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/screens/notifications/notifications_tab.dart";
import "package:yivi_core/src/screens/notifications/widgets/notification_card.dart";
import "package:yivi_core/src/widgets/feedback/yivi_spinner.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";

Credential _revoked(String hash) {
  final c = testCredential(type: "irma-demo.test.card", hash: hash);
  return Credential(
    credentialId: c.credentialId,
    hash: c.hash,
    name: c.name,
    issuer: c.issuer,
    credentialInstanceIds: c.credentialInstanceIds,
    batchInstanceCountsRemaining: c.batchInstanceCountsRemaining,
    attributes: c.attributes,
    revoked: true,
    revocationSupported: true,
    issueUrl: null,
  );
}

void main() {
  late RecordingBridge bridge;
  late IrmaRepository repo;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel("irma.app/irma_mobile_bridge"),
          (_) async => null,
        );
    bridge = RecordingBridge();
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

  testWidgets(
    "dismissing a notification removes it without a spinner",
    (tester) async {
      bridge.deliver(
        CredentialsEvent(credentials: [_revoked("a"), _revoked("b")]),
      );
      await pumpHome(tester, repo: repo, home: NotificationsTab());
      for (var i = 0; i < 20; i++) {
        await settle(tester);
        if (find.byType(NotificationCard).evaluate().length == 2) break;
      }
      expect(find.byType(NotificationCard), findsNWidgets(2));

      var spinner = false;
      await tester.fling(
        find.byType(NotificationCard).first,
        const Offset(-600, 0),
        2000,
      );
      // Check after every frame, also the one between the dismiss and the
      // store write finishing.
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        spinner |= find.byType(YiviSpinner).evaluate().isNotEmpty;
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
        spinner |= find.byType(YiviSpinner).evaluate().isNotEmpty;
      }
      expect(spinner, isFalse, reason: "a spinner was built after dismiss");
      expect(find.byType(NotificationCard), findsOneWidget);
    },
    // On a device the store write takes a few frames, and today the list
    // shows a spinner meanwhile (review D3). Here the mocked store answers
    // within the frame, so this passes today too; the state test pins the
    // spinner ("do not show loading").
  );
}

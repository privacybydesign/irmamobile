import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/screens/data/card_transition/card_transition.dart";
import "package:yivi_core/src/screens/data/credential_detail/credential_detail_screen.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/home/widgets/home_tab.dart";
import "package:yivi_core/src/screens/notifications/models/credential_status_notification.dart";
import "package:yivi_core/src/screens/notifications/notifications_provider.dart";
import "package:yivi_core/src/screens/notifications/widgets/notification_card.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/credential_card_art.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";

/// A card that expires in three days: "expiring soon", drawn as it is.
Credential _expiringSoon() => testCredential(
  type: "pbdf.sidn-pbdf.email",
  hash: "soon",
  name: "Email address",
  expiryDate:
      DateTime.now().add(const Duration(days: 3)).millisecondsSinceEpoch ~/
      1000,
);

/// A card that expired: drawn greyed.
Credential _expired() => testCredential(
  type: "pbdf.gemeente.address",
  hash: "gone",
  name: "Address",
  expiryDate: DateTime(2020).millisecondsSinceEpoch ~/ 1000,
);

const _upright = Size(390, 844);
const _uprightInsets = FakeViewPadding(top: 62, bottom: 34);

void iosTest(String description, WidgetTesterCallback body) => testWidgets(
  description,
  body,
  variant: TargetPlatformVariant.only(TargetPlatform.iOS),
);

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

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));

  /// The Notifications tab on an upright phone, under the card transitions,
  /// with a notification about each card.
  Future<void> pump(WidgetTester tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = _upright
      ..padding = _uprightInsets
      ..viewPadding = _uprightInsets;
    addTearDown(tester.view.reset);
    bridge.deliver(
      CredentialsEvent(credentials: [_expiringSoon(), _expired()]),
    );
    await pumpRoutes(
      tester,
      repo: repo,
      initialLocation: "/home",
      appBuilder: (context, child) =>
          CardTransitions(child: child ?? const SizedBox.shrink()),
      routes: [
        GoRoute(path: "/home", builder: (context, state) => HomeScreen()),
      ],
    );
    container(
      tester,
    ).read(homeTabProvider.notifier).select(HomeTab.notifications);
    for (var i = 0; i < 20; i++) {
      await settle(tester);
      if (find.byType(NotificationCard).evaluate().length == 2) break;
    }
    await tester.pumpAndSettle();
    expect(find.byType(NotificationCard), findsNWidgets(2));
  }

  /// The notification card about [hash], and its picture.
  Finder card(String hash) => find.byWidgetPredicate(
    (w) =>
        w is NotificationCard &&
        w.notification is CredentialStatusNotification &&
        (w.notification as CredentialStatusNotification).credentialHash == hash,
  );
  Finder picture(String hash) =>
      find.descendant(of: card(hash), matching: find.byType(CredentialCardArt));

  bool reaches(WidgetTester tester, Finder target) {
    final box = tester.renderObject(target);
    return tester
        .hitTestOnBinding(tester.getCenter(target))
        .path
        .any((e) => e.target == box);
  }

  bool read(WidgetTester tester, String hash) {
    final state = container(tester).read(notificationsProvider);
    return (state as NotificationsLoaded).notifications.any(
      (n) =>
          n is CredentialStatusNotification &&
          n.credentialHash == hash &&
          n.read,
    );
  }

  for (final hash in ["soon", "gone"]) {
    iosTest("a notification about a card ($hash) opens its details; closed, "
        "the list is back with the picture", (tester) async {
      await pump(tester);
      final place = tester.getRect(picture(hash));
      expect(read(tester, hash), isFalse);

      await tester.tap(card(hash));
      await tester.pumpAndSettle();
      final details = find.byType(CredentialDetailScreen);
      expect(details, findsOneWidget);
      expect(
        tester
            .widget<CredentialCardArt>(
              find
                  .descendant(
                    of: details,
                    matching: find.byType(CredentialCardArt),
                  )
                  .first,
            )
            .credential
            .hash,
        hash,
      );
      expect(read(tester, hash), isTrue);

      await tester.tap(find.byKey(const Key("credential_detail_done")));
      await tester.pumpAndSettle();
      expect(details, findsNothing);
      expect(container(tester).read(homeTabProvider), HomeTab.notifications);
      expect(tester.getRect(picture(hash)), place);
      expect(reaches(tester, picture(hash)), isTrue);
    });
  }
}

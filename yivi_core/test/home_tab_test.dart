import "dart:convert";

import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/client_preferences.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/providers/credentials_provider.dart";
import "package:yivi_core/src/providers/wallet_cards_provider.dart";
import "package:yivi_core/src/screens/activity/activity_tab.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/notifications/bloc/notifications_bloc.dart";
import "package:yivi_core/src/screens/notifications/notifications_tab.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";

class _FixedOrder extends CredentialOrderController {
  _FixedOrder(this.items);

  final List<Credential> items;

  @override
  Future<List<Credential>> build() async => items;
}

final _wallet = [testCredential(type: "pbdf.sidn-pbdf.email", hash: "email")];

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
    bridge.deliver(
      ClientPreferencesEvent(
        clientPreferences: ClientPreferences(developerMode: false),
      ),
    );
  });
  tearDown(() => repo.close());

  /// The home screen on an upright iPhone, with the state holders the app
  /// gives it.
  Future<GoRouter> pump(WidgetTester tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844)
      ..padding = const FakeViewPadding(top: 62, bottom: 34)
      ..viewPadding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);
    final notifications = NotificationsBloc(repo: repo)..add(Initialize());
    addTearDown(() async {
      await notifications.close();
    });
    final router = await pumpRoutes(
      tester,
      repo: repo,
      initialLocation: "/home",
      overrides: [
        credentialsProvider.overrideWith(
          (ref) => Stream.value((credentials: _wallet, problematic: [])),
        ),
        credentialOrderControllerProvider.overrideWith(
          () => _FixedOrder(_wallet),
        ),
      ],
      routes: [
        ShellRoute(
          builder: (context, state, child) => MultiBlocProvider(
            providers: [
              BlocProvider<NotificationsBloc>.value(value: notifications),
            ],
            child: child,
          ),
          routes: [
            GoRoute(path: "/home", builder: (context, state) => HomeScreen()),
          ],
        ),
      ],
    );
    for (var i = 0; i < 5; i++) {
      await settle(tester);
    }
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> tapTab(WidgetTester tester, String tab) async {
    await tester.tap(find.byKey(Key("nav_button_$tab")));
    // A fixed while: the Activity tab's spinner never settles here.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await settle(tester);
  }

  /// The Activity tab leaves its query timers; unmount and run them out.
  Future<void> leave(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  }

  bool shown(Type tab) => find.byType(tab).hitTestable().evaluate().isNotEmpty;

  testWidgets("leaving Notifications marks what it showed read", (
    tester,
  ) async {
    bridge.deliver(CredentialsEvent(credentials: [_revoked("a")]));
    await pump(tester);
    await tapTab(tester, "notifications");
    expect(shown(NotificationsTab), isTrue);
    await tapTab(tester, "data");
    for (var i = 0; i < 5; i++) {
      await settle(tester);
    }
    final raw = await tester.runAsync(
      () => repo.preferences.serializedNotifications.stream.first,
    );
    final records = (jsonDecode(raw!) as List).cast<Map<String, dynamic>>();
    expect(records, isNotEmpty);
    expect(records.every((r) => r["read"] == true), isTrue);
  });

  testWidgets("tapping the tab that is open keeps it open", (tester) async {
    await pump(tester);
    await tapTab(tester, "activity");
    expect(shown(ActivityTab), isTrue);
    await tapTab(tester, "activity");
    expect(shown(ActivityTab), isTrue);
    expect(shown(DataTab), isFalse);
    await leave(tester);
  });

  testWidgets("back on another tab goes to Data", (tester) async {
    await pump(tester);
    await tapTab(tester, "activity");
    expect(shown(ActivityTab), isTrue);
    await tester.binding.handlePopRoute();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(shown(DataTab), isTrue);
    expect(shown(ActivityTab), isFalse);
    await leave(tester);
  });
}

import "dart:convert";

import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/screens/notifications/models/credential_status_notification.dart";
import "package:yivi_core/src/screens/notifications/models/notification.dart";
import "package:yivi_core/src/screens/notifications/notifications_provider.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";

/// Drives the notifications state the way the app does: a first load, a
/// reload, mark read, mark all read and dismiss. Only this class knows
/// which state holder it drives.
class _Driver {
  final ProviderContainer _container;

  _Driver(IrmaRepository repo)
    : _container = ProviderContainer(
        overrides: [irmaRepositoryProvider.overrideWithValue(repo)],
      ) {
    _keepAlive = _container.listen(notificationsProvider, (_, s) {
      if (s is NotificationsLoading) sawLoading = true;
    });
  }

  late final ProviderSubscription<NotificationsState> _keepAlive;

  NotificationsNotifier get _notifier =>
      _container.read(notificationsProvider.notifier);
  NotificationsState get _state => _container.read(notificationsProvider);

  /// Whether the last action went through a loading state on its way.
  bool sawLoading = false;

  Future<List<Notification>> load() => _until(() => _state);

  Future<List<Notification>> reload() => _until(_notifier.reload);

  Future<List<Notification>> markRead(String id) =>
      _until(() => _notifier.markRead(id));

  Future<List<Notification>> markAllRead() => _until(_notifier.markAllRead);

  Future<List<Notification>> dismiss(String id) =>
      _until(() => _notifier.dismiss(id));

  int get unreadCount => (_state as NotificationsLoaded).unreadCount;
  bool get hasUnread => (_state as NotificationsLoaded).hasUnread;

  /// Runs [act] and waits until the list is loaded and every queued store
  /// write is done.
  Future<List<Notification>> _until(void Function() act) async {
    sawLoading = false;
    act();
    for (var i = 0; i < 1000; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      if (_state is NotificationsLoaded) break;
    }
    // The writes queued after the change.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return (_state as NotificationsLoaded).notifications;
  }

  Future<void> close() async {
    _keepAlive.close();
    _container.dispose();
  }
}

Credential _card(
  String hash, {
  bool revoked = false,
  DateTime? expires,
  String type = "irma-demo.test.card",
}) {
  final c = testCredential(
    type: type,
    hash: hash,
    expiryDate: expires == null ? null : expires.millisecondsSinceEpoch ~/ 1000,
  );
  return Credential(
    credentialId: c.credentialId,
    hash: c.hash,
    name: c.name,
    issuer: c.issuer,
    credentialInstanceIds: c.credentialInstanceIds,
    batchInstanceCountsRemaining: c.batchInstanceCountsRemaining,
    attributes: c.attributes,
    revoked: revoked,
    revocationSupported: revoked,
    issueUrl: null,
    expiryDate: c.expiryDate,
  );
}

DateTime _inDays(int days) => DateTime.now().add(Duration(days: days));

void main() {
  late RecordingBridge bridge;
  late IrmaPreferences prefs;
  late IrmaRepository repo;
  late _Driver driver;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel("irma.app/irma_mobile_bridge"),
          (_) async => null,
        );
    bridge = RecordingBridge();
    prefs = await freshPreferences();
    repo = IrmaRepository(client: bridge, preferences: prefs);
    driver = _Driver(repo);
  });

  tearDown(() async {
    await driver.close();
    await repo.close();
  });

  /// The app's cards, as Go sends them; waits until the repository has them.
  Future<void> cards(List<Credential> credentials) async {
    bridge.deliver(CredentialsEvent(credentials: credentials));
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  Future<List<Map<String, dynamic>>> stored() async {
    final raw = await prefs.serializedNotifications.stream.first;
    if (raw.isEmpty) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  CredentialStatusNotificationType typeOf(Notification n) =>
      (n as CredentialStatusNotification).type;

  test("a revoked, an expired and an expiring card: three unread", () async {
    await cards([
      _card("a", revoked: true),
      _card("b", expires: _inDays(-1)),
      _card("c", expires: _inDays(3)),
      _card("d", expires: _inDays(100)),
    ]);
    final list = await driver.load();
    expect(list.map(typeOf), [
      CredentialStatusNotificationType.revoked,
      CredentialStatusNotificationType.expired,
      CredentialStatusNotificationType.expiringSoon,
    ]);
    expect(list.every((n) => !n.read), isTrue);
    expect(driver.unreadCount, 3);
    expect(driver.hasUnread, isTrue);
    expect((await stored()).map((r) => r["credentialHash"]), ["a", "b", "c"]);
  });

  test("a stored record keeps its id, flags and time", () async {
    await cards([_card("a", revoked: true)]);
    final first = (await driver.load()).single;
    await driver.markRead(first.id);
    final again = (await driver.reload()).single;
    expect(again.id, first.id);
    expect(again.read, isTrue);
    expect(again.timestamp, first.timestamp);
  });

  test("a record whose card is gone is dropped on reload", () async {
    await cards([_card("a", revoked: true), _card("b", revoked: true)]);
    await driver.load();
    await cards([_card("a", revoked: true)]);
    final list = await driver.reload();
    expect(list.map((n) => n.id).length, 1);
    expect((await stored()).map((r) => r["credentialHash"]), ["a"]);
  });

  test("expiring soon, then expired: a new record, the old one gone", () async {
    await cards([_card("a", expires: _inDays(3))]);
    final soon = (await driver.load()).single;
    await cards([_card("a", expires: _inDays(-1))]);
    final expired = (await driver.reload()).single;
    expect(typeOf(expired), CredentialStatusNotificationType.expired);
    expect(expired.id, isNot(soon.id));
    expect((await stored()).single["type"], "expired");
  });

  test("mark one read, mark all read, dismiss", () async {
    await cards([
      _card("a", revoked: true),
      _card("b", revoked: true),
      _card("c", revoked: true),
    ]);
    final list = await driver.load();
    var now = await driver.markRead(list[0].id);
    expect(now.where((n) => n.read).length, 1);
    expect(driver.unreadCount, 2);
    expect((await stored()).where((r) => r["read"] == true).length, 1);

    now = await driver.markAllRead();
    expect(now.every((n) => n.read), isTrue);
    expect(driver.hasUnread, isFalse);
    expect((await stored()).every((r) => r["read"] == true), isTrue);

    now = await driver.dismiss(list[1].id);
    expect(now.map((n) => n.id), [list[0].id, list[2].id]);
    expect(
      (await stored()).singleWhere((r) => r["id"] == list[1].id)["softDeleted"],
      isTrue,
    );
  });

  test("a dismissed notification stays hidden after a fresh load", () async {
    await cards([_card("a", revoked: true), _card("b", revoked: true)]);
    final list = await driver.load();
    await driver.dismiss(list[0].id);
    await driver.close();
    driver = _Driver(repo);
    final again = await driver.load();
    expect(again.map((n) => n.id), [list[1].id]);
  });

  test("corrupt stored records: an empty start, the store cleared", () async {
    await prefs.serializedNotifications.set("{not json");
    await cards([_card("a", revoked: true)]);
    final list = await driver.load();
    expect(list.length, 1);
    expect((await stored()).length, 1);
  });

  test("mark read, mark all read and dismiss do not show loading", () async {
    await cards([_card("a", revoked: true), _card("b", revoked: true)]);
    final list = await driver.load();
    await driver.markRead(list[0].id);
    expect(driver.sawLoading, isFalse, reason: "mark read");
    await driver.markAllRead();
    expect(driver.sawLoading, isFalse, reason: "mark all read");
    await driver.dismiss(list[1].id);
    expect(driver.sawLoading, isFalse, reason: "dismiss");
  });

  test("credentials that never arrive: an empty list after 5 s", () async {
    final list = await driver.load();
    expect(list, isEmpty);
  }, timeout: const Timeout(Duration(seconds: 15)));
}

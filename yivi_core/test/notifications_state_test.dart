import "dart:convert";

import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/screens/notifications/bloc/notifications_bloc.dart";
import "package:yivi_core/src/screens/notifications/models/credential_status_notification.dart";
import "package:yivi_core/src/screens/notifications/models/notification.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";

/// Drives the notifications state the way the app does: a first load, a
/// reload, mark read, mark all read and dismiss. Only this class knows
/// which state holder it drives.
class _Driver {
  final NotificationsBloc _bloc;

  _Driver(IrmaRepository repo) : _bloc = NotificationsBloc(repo: repo);

  Future<List<Notification>> load() =>
      _until(() => _bloc.add(Initialize()), initial: true);

  Future<List<Notification>> reload() =>
      _until(() => _bloc.add(LoadNotifications()));

  Future<List<Notification>> markRead(String id) =>
      _until(() => _bloc.add(MarkNotificationAsRead(id)));

  Future<List<Notification>> markAllRead() =>
      _until(() => _bloc.add(MarkAllNotificationsAsRead()));

  Future<List<Notification>> dismiss(String id) =>
      _until(() => _bloc.add(SoftDeleteNotification(id)));

  /// Whether the last action went through a loading state on its way.
  bool sawLoading = false;

  int get unreadCount => (_bloc.state as NotificationsLoaded).unreadCount;
  bool get hasUnread =>
      (_bloc.state as NotificationsLoaded).hasUnreadNotifications;

  /// Runs [act] and waits for the loaded list that follows it.
  Future<List<Notification>> _until(
    void Function() act, {
    bool initial = false,
  }) async {
    sawLoading = false;
    final watch = _bloc.stream.listen((s) {
      if (s is NotificationsLoading) sawLoading = true;
    });
    final next = _bloc.stream
        .where((s) => s is NotificationsLoaded)
        .cast<NotificationsLoaded>()
        .first;
    act();
    await next;
    await watch.cancel();
    return (await next).notifications;
  }

  Future<void> close() => _bloc.close();
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

  void cards(List<Credential> credentials) =>
      bridge.deliver(CredentialsEvent(credentials: credentials));

  Future<List<Map<String, dynamic>>> stored() async {
    final raw = await prefs.serializedNotifications.stream.first;
    if (raw.isEmpty) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  CredentialStatusNotificationType typeOf(Notification n) =>
      (n as CredentialStatusNotification).type;

  test("a revoked, an expired and an expiring card: three unread", () async {
    cards([
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
    cards([_card("a", revoked: true)]);
    final first = (await driver.load()).single;
    await driver.markRead(first.id);
    final again = (await driver.reload()).single;
    expect(again.id, first.id);
    expect(again.read, isTrue);
    expect(again.timestamp, first.timestamp);
  });

  test("a record whose card is gone is dropped on reload", () async {
    cards([_card("a", revoked: true), _card("b", revoked: true)]);
    await driver.load();
    cards([_card("a", revoked: true)]);
    final list = await driver.reload();
    expect(list.map((n) => n.id).length, 1);
    expect((await stored()).map((r) => r["credentialHash"]), ["a"]);
  });

  test("expiring soon, then expired: a new record, the old one gone", () async {
    cards([_card("a", expires: _inDays(3))]);
    final soon = (await driver.load()).single;
    cards([_card("a", expires: _inDays(-1))]);
    final expired = (await driver.reload()).single;
    expect(typeOf(expired), CredentialStatusNotificationType.expired);
    expect(expired.id, isNot(soon.id));
    expect((await stored()).single["type"], "expired");
  });

  test("mark one read, mark all read, dismiss", () async {
    cards([
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
    cards([_card("a", revoked: true), _card("b", revoked: true)]);
    final list = await driver.load();
    await driver.dismiss(list[0].id);
    await driver.close();
    driver = _Driver(repo);
    final again = await driver.load();
    expect(again.map((n) => n.id), [list[1].id]);
  });

  test("corrupt stored records: an empty start, the store cleared", () async {
    await prefs.serializedNotifications.set("{not json");
    cards([_card("a", revoked: true)]);
    final list = await driver.load();
    expect(list.length, 1);
    expect((await stored()).length, 1);
  });

  test(
    "mark read, mark all read and dismiss do not show loading",
    () async {
      cards([_card("a", revoked: true), _card("b", revoked: true)]);
      final list = await driver.load();
      await driver.markRead(list[0].id);
      expect(driver.sawLoading, isFalse, reason: "mark read");
      await driver.markAllRead();
      expect(driver.sawLoading, isFalse, reason: "mark all read");
      await driver.dismiss(list[1].id);
      expect(driver.sawLoading, isFalse, reason: "dismiss");
    },
    // Today every change goes through Loading, and the tab shows a spinner
    // for it (review D3). The skip goes in step 5.7.
    skip: true,
  );

  test("credentials that never arrive: an empty list after 5 s", () async {
    final list = await driver.load();
    expect(list, isEmpty);
  }, timeout: const Timeout(Duration(seconds: 15)));
}

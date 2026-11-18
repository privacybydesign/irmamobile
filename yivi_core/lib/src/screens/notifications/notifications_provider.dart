import "dart:convert";

import "package:flutter/widgets.dart"
    show AppLifecycleListener, AppLifecycleState;
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../data/irma_repository.dart";
import "../../providers/irma_repository_provider.dart";
import "../../sentry/sentry.dart";
import "../../util/serial_queue.dart";
import "handlers/credential_status_notifications_handler.dart";
import "handlers/notification_handler.dart";
import "models/credential_status_notification_record.dart";
import "models/notification.dart";

/// The notifications the Notifications tab shows, kept as records in the
/// preferences.
final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(
      NotificationsNotifier.new,
    );

sealed class NotificationsState {
  const NotificationsState();
}

/// The records are being read or refreshed.
final class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

final class NotificationsLoaded extends NotificationsState {
  /// The notifications to show: the dismissed ones are left out.
  final List<Notification> notifications;

  NotificationsLoaded(List<Notification> notifications)
    : notifications = List.unmodifiable(notifications);

  /// How many notifications are not read yet.
  int get unreadCount => notifications.where((n) => !n.read).length;

  bool get hasUnread => notifications.any((n) => !n.read);
}

/// Loads the notifications from the cards in the app and the stored
/// records, and keeps the read and dismissed flags.
///
/// Loads and writes to the store run one at a time, in the order asked.
/// Marking read and dismissing change the list at
/// once (no loading state, so no spinner and no blink of the unread dot);
/// asked during a load, they are applied when the load is done.
class NotificationsNotifier extends Notifier<NotificationsState> {
  late IrmaRepository _repo;
  late SerialQueue _queue;

  /// Bumped on every build, so jobs of an earlier build do nothing.
  int _generation = 0;

  List<CredentialStatusNotificationRecord> _records = [];

  /// Every notification, dismissed ones included.
  List<Notification> _all = [];

  final List<NotificationHandler> _handlers = [
    CredentialStatusNotificationsHandler(),
  ];

  @override
  NotificationsState build() {
    _repo = ref.watch(irmaRepositoryProvider);
    _queue = SerialQueue();
    _records = [];
    _all = [];
    final generation = ++_generation;
    _queue.add(() async {
      final stored =
          await _repo.preferences.serializedNotifications.stream.first;
      if (generation != _generation) return;
      _records = _recordsFromJson(stored);
      await _refresh(generation);
    });
    // The cards may have changed while the app was away.
    final lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        if (state == AppLifecycleState.resumed) reload();
      },
    );
    ref.onDispose(lifecycle.dispose);
    return const NotificationsLoading();
  }

  /// Reads the cards again: a pull to refresh, the app coming back.
  Future<void> reload() {
    state = const NotificationsLoading();
    final generation = _generation;
    return _queue.add(() => _refresh(generation));
  }

  void markRead(String id) =>
      _change((n) => n.id == id ? n.copyWith(read: true) : n);

  void markAllRead() => _change((n) => n.copyWith(read: true));

  void dismiss(String id) =>
      _change((n) => n.id == id ? n.copyWith(softDeleted: true) : n);

  /// Applies [change] to every notification and its record, then stores
  /// the records.
  void _change(Notification Function(Notification n) change) {
    final generation = _generation;
    void apply() {
      _all = _all.map(change).toList();
      final byId = {for (final n in _all) n.id: n};
      _records = [
        for (final r in _records)
          if (byId[r.id] case final n?)
            r.copyWith(read: n.read, softDeleted: n.softDeleted)
          else
            r,
      ];
      state = NotificationsLoaded(_visible());
    }

    if (state is NotificationsLoaded) {
      apply();
      _queue.add(() => _persist(generation));
    } else {
      _queue.add(() async {
        if (generation != _generation) return;
        apply();
        await _persist(generation);
      });
    }
  }

  /// Rebuilds the notifications from each handler, drops the records of
  /// cards that are gone, and stores the rest.
  Future<void> _refresh(int generation) async {
    final notifications = <Notification>[];
    final records = <CredentialStatusNotificationRecord>[];
    for (final handler in _handlers) {
      final result = await handler.load(_repo, _records);
      notifications.addAll(result.notifications);
      records.addAll(result.updatedRecords);
    }
    if (generation != _generation) return;
    _records = records;
    _all = notifications;
    await _persist(generation);
    if (generation != _generation) return;
    state = NotificationsLoaded(_visible());
  }

  List<Notification> _visible() => _all.where((n) => !n.softDeleted).toList();

  Future<void> _persist(int generation) async {
    if (generation != _generation) return;
    await _repo.preferences.serializedNotifications.set(
      jsonEncode(_records.map((r) => r.toJson()).toList()),
    );
  }

  List<CredentialStatusNotificationRecord> _recordsFromJson(String stored) {
    if (stored.isEmpty) return [];
    try {
      return [
        for (final e in jsonDecode(stored) as List<dynamic>)
          CredentialStatusNotificationRecord.fromJson(
            e as Map<String, dynamic>,
          ),
      ];
    } catch (e, stackTrace) {
      // Old-format data (full Notification objects) or otherwise corrupted
      // cache: clear and start fresh.
      reportError(e, stackTrace);
      _repo.preferences.serializedNotifications.set("");
      return [];
    }
  }
}

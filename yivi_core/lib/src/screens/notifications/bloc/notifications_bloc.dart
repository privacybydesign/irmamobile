import "dart:convert";

import "package:equatable/equatable.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "../../../data/irma_repository.dart";
import "../../../sentry/sentry.dart";
import "../handlers/credential_status_notifications_handler.dart";
import "../handlers/notification_handler.dart";
import "../models/credential_status_notification_record.dart";
import "../models/notification.dart";

part "notifications_event.dart";
part "notifications_state.dart";

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final IrmaRepository _repo;
  List<CredentialStatusNotificationRecord> _records = [];
  List<Notification> _notifications = [];

  final List<NotificationHandler> _notificationHandlers = [
    CredentialStatusNotificationsHandler(),
  ];

  NotificationsBloc({required IrmaRepository repo})
    : _repo = repo,
      super((NotificationsInitial()));

  @override
  Stream<NotificationsState> mapEventToState(NotificationsEvent event) async* {
    if (event is Initialize) {
      yield* _mapInitToState();
    } else if (event is LoadNotifications) {
      yield* _mapLoadNotificationsToState();
    } else if (event is MarkAllNotificationsAsRead) {
      yield* _mapMarkAllNotificationsAsReadToState();
    } else if (event is MarkNotificationAsRead) {
      yield* _mapMarkNotificationAsReadToState(event.notificationId);
    } else if (event is SoftDeleteNotification) {
      yield* _mapSoftDeleteNotificationToState(event.notificationId);
    } else {
      throw UnimplementedError();
    }
  }

  Stream<NotificationsState> _mapInitToState() async* {
    yield NotificationsLoading();

    final serializedRecords = await _repo.preferences
        .getSerializedNotifications()
        .first;
    _records = _recordsFromJson(serializedRecords);

    await _refresh();

    yield NotificationsInitialized(_visibleNotifications());
  }

  Stream<NotificationsState> _mapLoadNotificationsToState() async* {
    yield NotificationsLoading();
    await _refresh();
    yield NotificationsInitialized(_visibleNotifications());
  }

  Stream<NotificationsState> _mapMarkAllNotificationsAsReadToState() async* {
    yield NotificationsLoading();

    _records = _records.map((r) => r.copyWith(read: true)).toList();
    _notifications = _buildNotifications(_records);
    await _persistRecords();

    yield NotificationsLoaded(_visibleNotifications());
  }

  Stream<NotificationsState> _mapMarkNotificationAsReadToState(
    String notificationId,
  ) async* {
    yield NotificationsLoading();

    _records = _records
        .map((r) => r.id == notificationId ? r.copyWith(read: true) : r)
        .toList();
    _notifications = _buildNotifications(_records);
    await _persistRecords();

    yield NotificationsLoaded(_visibleNotifications());
  }

  Stream<NotificationsState> _mapSoftDeleteNotificationToState(
    String notificationId,
  ) async* {
    yield NotificationsLoading();

    _records = _records
        .map((r) => r.id == notificationId ? r.copyWith(softDeleted: true) : r)
        .toList();
    _notifications = _buildNotifications(_records);
    await _persistRecords();

    yield NotificationsLoaded(_visibleNotifications());
  }

  /// Re-derives runtime notifications and updated records from each handler,
  /// drops orphan records, and persists the new record list.
  Future<void> _refresh() async {
    final List<Notification> notifications = [];
    final List<CredentialStatusNotificationRecord> updatedRecords = [];

    for (final handler in _notificationHandlers) {
      final result = await handler.load(_repo, _records);
      notifications.addAll(result.notifications);
      updatedRecords.addAll(result.updatedRecords);
    }

    _records = updatedRecords;
    _notifications = notifications;
    await _persistRecords();
  }

  /// Re-derives runtime notifications from the current records without
  /// touching the underlying credential store. Used after user-state
  /// mutations (read/dismiss).
  List<Notification> _buildNotifications(
    List<CredentialStatusNotificationRecord> records,
  ) {
    // Reconstruct from the existing notification list by id, since records
    // alone don't carry display data. Mutated user-state flags are copied
    // back from the updated record.
    final byId = {for (final n in _notifications) n.id: n};
    return records
        .map((r) {
          final base = byId[r.id];
          if (base == null) return null;
          base.read = r.read;
          base.softDeleted = r.softDeleted;
          return base;
        })
        .whereType<Notification>()
        .toList();
  }

  List<Notification> _visibleNotifications() =>
      _notifications.where((n) => !n.softDeleted).toList();

  Future<void> _persistRecords() async {
    final serialized = jsonEncode(_records.map((r) => r.toJson()).toList());
    await _repo.preferences.setSerializedNotifications(serialized);
  }

  List<CredentialStatusNotificationRecord> _recordsFromJson(String serialized) {
    if (serialized.isEmpty) return [];

    try {
      final decoded = jsonDecode(serialized) as List<dynamic>;
      return decoded
          .map(
            (e) => CredentialStatusNotificationRecord.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e, stackTrace) {
      // Old-format data (full Notification objects) or otherwise corrupted
      // cache: clear and start fresh.
      reportError(e, stackTrace);
      _repo.preferences.setSerializedNotifications("");
      return [];
    }
  }
}

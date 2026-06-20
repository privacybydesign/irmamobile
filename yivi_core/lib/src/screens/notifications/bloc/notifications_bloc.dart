import "dart:convert";

import "package:equatable/equatable.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "../../../data/irma_repository.dart";
import "../../../sentry/sentry.dart";
import "../../../util/bloc_event_transformer.dart";
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
      super((NotificationsInitial())) {
    // A single handler with a sequential transformer is used (instead of one
    // `on<T>` per event type) so that all events are processed one at a time,
    // matching the original `mapEventToState` ordering. This is required
    // because the handlers mutate shared fields (`_records`, `_notifications`)
    // across `await`s; concurrent processing would corrupt that state.
    on<NotificationsEvent>((event, emit) async {
      if (event is Initialize) {
        await _onInitialize(event, emit);
      } else if (event is LoadNotifications) {
        await _onLoadNotifications(event, emit);
      } else if (event is MarkAllNotificationsAsRead) {
        await _onMarkAllNotificationsAsRead(event, emit);
      } else if (event is MarkNotificationAsRead) {
        await _onMarkNotificationAsRead(event, emit);
      } else if (event is SoftDeleteNotification) {
        await _onSoftDeleteNotification(event, emit);
      } else {
        throw UnimplementedError();
      }
    }, transformer: sequentialTransformer());
  }

  Future<void> _onInitialize(
    Initialize event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());

    final serializedRecords = await _repo.preferences
        .getSerializedNotifications()
        .first;
    _records = _recordsFromJson(serializedRecords);

    await _refresh();

    emit(NotificationsInitialized(_visibleNotifications()));
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());
    await _refresh();
    emit(NotificationsInitialized(_visibleNotifications()));
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());

    _records = _records.map((r) => r.copyWith(read: true)).toList();
    _notifications = _buildNotifications(_records);
    await _persistRecords();

    emit(NotificationsLoaded(_visibleNotifications()));
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());

    _records = _records
        .map((r) => r.id == event.notificationId ? r.copyWith(read: true) : r)
        .toList();
    _notifications = _buildNotifications(_records);
    await _persistRecords();

    emit(NotificationsLoaded(_visibleNotifications()));
  }

  Future<void> _onSoftDeleteNotification(
    SoftDeleteNotification event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());

    _records = _records
        .map(
          (r) =>
              r.id == event.notificationId ? r.copyWith(softDeleted: true) : r,
        )
        .toList();
    _notifications = _buildNotifications(_records);
    await _persistRecords();

    emit(NotificationsLoaded(_visibleNotifications()));
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

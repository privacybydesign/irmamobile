import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/irma_repository.dart';
import '../../../sentry/sentry.dart';
import '../handlers/credential_status_notifications_handler.dart';
import '../handlers/notification_handler.dart';
import '../models/notification.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final IrmaRepository _repo;
  List<Notification> _notifications = [];

  final List<NotificationHandler> _notificationHandlers = [
    CredentialStatusNotificationsHandler(),
  ];

  NotificationsBloc({
    required IrmaRepository repo,
  })  : _repo = repo,
        super((NotificationsInitial()));

  @override
  Stream<NotificationsState> mapEventToState(NotificationsEvent event) async* {
    // The Initialize event should be called right after the bloc is created
    // It reads from cache, cleans up the notifications and loads new ones
    if (event is Initialize) {
      yield* _mapInitToState();
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

    List<Notification> initialNotifications = [];

    // Load the cached notifications
    final serializedNotifications = await _repo.preferences.getSerializedNotifications().first;
    initialNotifications = _notificationsFromJson(serializedNotifications);

    // Run the clean up method of each notification handler
    for (final notificationHandler in _notificationHandlers) {
      initialNotifications = notificationHandler.cleanUp(_repo, initialNotifications);
    }

    // Load the new notifications
    for (final notificationHandler in _notificationHandlers) {
      initialNotifications = await notificationHandler.loadNotifications(_repo, initialNotifications);
    }

    // Update the cached notifications
    _updateCachedNotifications(initialNotifications);

    _notifications = initialNotifications;
    yield NotificationsInitialized(initialNotifications);
  }

  Stream<NotificationsState> _mapMarkAllNotificationsAsReadToState() async* {
    yield NotificationsLoading();

    final List<Notification> updatedNotifications = _notifications;

    for (final notification in updatedNotifications) {
      notification.read = true;
    }

    _updateCachedNotifications(updatedNotifications);

    _notifications = updatedNotifications;
    final filteredNotifications = _filterNonSoftDeletedNotifications(_notifications);

    yield NotificationsLoaded(filteredNotifications);
  }

  Stream<NotificationsState> _mapMarkNotificationAsReadToState(String notificationId) async* {
    yield NotificationsLoading();

    final List<Notification> updatedNotifications = _notifications;

    final notificationIndex = updatedNotifications.indexWhere((notification) => notification.id == notificationId);
    if (notificationIndex != -1) {
      updatedNotifications[notificationIndex].read = true;
    }
    _updateCachedNotifications(updatedNotifications);

    _notifications = updatedNotifications;
    final filteredNotifications = _filterNonSoftDeletedNotifications(_notifications);

    yield NotificationsLoaded(filteredNotifications);
  }

  Stream<NotificationsState> _mapSoftDeleteNotificationToState(String notificationId) async* {
    yield NotificationsLoading();

    final List<Notification> updatedNotifications = _notifications;

    final notificationIndex = updatedNotifications.indexWhere((notification) => notification.id == notificationId);
    if (notificationIndex != -1) {
      updatedNotifications[notificationIndex].softDeleted = true;
    }
    _updateCachedNotifications(updatedNotifications);

    _notifications = updatedNotifications;
    final filteredNotifications = _filterNonSoftDeletedNotifications(_notifications);

    yield NotificationsLoaded(filteredNotifications);
  }

  List<Notification> _filterNonSoftDeletedNotifications(Iterable<Notification> notifications) {
    final filteredNotifications = notifications.where((notification) => !notification.softDeleted).toList();
    return filteredNotifications;
  }

  Future<void> _updateCachedNotifications(List<Notification> updatedNotifications) async {
    final serializedNotifications = _notificationsToJson(updatedNotifications);
    await _repo.preferences.setSerializedNotifications(serializedNotifications);
  }

  List<Notification> _notificationsFromJson(String serializedNotifications) {
    List<Notification> notifications = [];

    try {
      if (serializedNotifications != '') {
        final jsonDecodedNotifications = jsonDecode(serializedNotifications);
        notifications = jsonDecodedNotifications
            .map<Notification>(
              (jsonDecodedNotification) => Notification.fromJson(jsonDecodedNotification),
            )
            .toList();
      }
    } catch (e, stackTrace) {
      // If the cache is corrupted, we report the error to Sentry
      reportError(e, stackTrace);

      // If the cache is corrupted, we clear it and return an empty list
      _repo.preferences.setSerializedNotifications('');
    }

    return notifications;
  }

  String _notificationsToJson(List<Notification> notifications) {
    final mappedNotifications = notifications.map((notification) => notification.toJson()).toList();
    return jsonEncode(mappedNotifications);
  }
}

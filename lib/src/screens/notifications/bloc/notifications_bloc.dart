import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/irma_repository.dart';
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
    if (event is Initialize) {
      yield* _mapInitToState();
    } else if (event is SoftDeleteNotification) {
      yield* _mapSoftDeleteNotificationToState(event.notificationId);
    } else {
      throw UnimplementedError();
    }
  }

  Stream<NotificationsState> _mapInitToState() async* {
    yield NotificationsLoading();

    List<Notification> initialNotification = [];

    // Load the cached notifications
    final serializedNotifications = await _repo.preferences.getSerializedNotifications().first;
    initialNotification = _notificationsFromJson(serializedNotifications);

    // Run the clean up method of each notification handler
    for (final notificationHandler in _notificationHandlers) {
      initialNotification = notificationHandler.cleanUp(_repo, initialNotification);
    }

    //Load the new notifications
    for (final notificationHandler in _notificationHandlers) {
      initialNotification = await notificationHandler.loadNotifications(_repo, initialNotification);
    }

    // Update the cached notifications
    _updateCachedNotifications(initialNotification);

    _notifications = initialNotification;
    yield NotificationsInitialized(initialNotification);
  }

  Stream<NotificationsState> _mapSoftDeleteNotificationToState(String notificationId) async* {
    yield NotificationsLoading();

    final notificationIndex = _notifications.indexWhere((notification) => notification.id == notificationId);
    if (notificationIndex != -1) {
      _notifications[notificationIndex].softDeleted = true;
    }
    _updateCachedNotifications(_notifications);

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

    if (serializedNotifications != '') {
      final jsonDecodedNotifications = jsonDecode(serializedNotifications);
      notifications = jsonDecodedNotifications
          .map<Notification>(
            (jsonDecodedNotification) => Notification.fromJson(jsonDecodedNotification),
          )
          .toList();
    }

    return notifications;
  }

  String _notificationsToJson(List<Notification> notifications) {
    final mappedNotifications = notifications.map((notification) => notification.toJson()).toList();
    return jsonEncode(mappedNotifications);
  }
}

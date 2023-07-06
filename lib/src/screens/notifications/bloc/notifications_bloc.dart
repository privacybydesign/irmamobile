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
  List<Notification> notifications = [];

  final List<NotificationHandler> _notificationHandlers = [
    CredentialStatusNotificationsHandler(),
  ];

  NotificationsBloc({
    required IrmaRepository repo,
  })  : _repo = repo,
        super((NotificationsInitial()));

  @override
  Stream<NotificationsState> mapEventToState(NotificationsEvent event) async* {
    if (event is LoadCachedNotifications) {
      yield* _mapLoadCachedNotificationsToState();
    } else if (event is LoadNewNotifications) {
      yield* _mapLoadNewNotificationsToState();
    } else if (event is SoftDeleteNotification) {
      yield* _mapSoftDeleteNotificationToState(event.notificationId);
    } else if (event is HardDeleteNotification) {
      yield* _mapHardDeleteNotificationToState(event.notificationId);
    } else {
      throw UnimplementedError();
    }
  }

  Stream<NotificationsState> _mapHardDeleteNotificationToState(String notificationId) async* {
    yield NotificationsLoading();

    notifications.removeWhere((notification) => notification.id == notificationId);

    final filteredNotifications = _filterNonSoftDeletedNotifications(notifications);
    yield NotificationsLoaded(filteredNotifications);
  }

  Stream<NotificationsState> _mapSoftDeleteNotificationToState(String notificationId) async* {
    yield NotificationsLoading();

    final notificationIndex = notifications.indexWhere((notification) => notification.id == notificationId);
    if (notificationIndex != -1) {
      notifications[notificationIndex].softDeleted = true;
    }

    final filteredNotifications = _filterNonSoftDeletedNotifications(notifications);
    yield NotificationsLoaded(filteredNotifications);
  }

  List<Notification> _filterNonSoftDeletedNotifications(Iterable<Notification> notifications) {
    final filteredNotifications = notifications.where((notification) => !notification.softDeleted).toList();
    return filteredNotifications;
  }

  Stream<NotificationsState> _mapLoadCachedNotificationsToState() async* {
    yield NotificationsLoading();

    final serializedNotifications = await _repo.preferences.getSerializedNotifications().first;
    final loadedNotifications = _notificationsFromJson(serializedNotifications);

    final filteredNotifications = _filterNonSoftDeletedNotifications(loadedNotifications);
    yield NotificationsLoaded(filteredNotifications);
  }

  Stream<NotificationsState> _mapLoadNewNotificationsToState() async* {
    yield NotificationsLoading();

    for (final notificationHandler in _notificationHandlers) {
      notifications = await notificationHandler.loadNotifications(_repo, notifications);
    }

    await _updateCacheNotifications(notifications);

    final filteredNotifications = _filterNonSoftDeletedNotifications(notifications);
    yield NotificationsLoaded(filteredNotifications);
  }

  Future<void> _updateCacheNotifications(List<Notification> updatedNotifications) async {
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

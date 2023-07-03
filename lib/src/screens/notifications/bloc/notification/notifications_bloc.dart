import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../../data/irma_repository.dart';
import '../../models/notification.dart';
import '../credential_status_notification/credential_status_notification_cubit.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

// BLoC containing the general notifications logic
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final IrmaRepository _repo;

  List<Notification> notifications = [];

  final CredentialStatusNotificationCubit _credentialNotificationsCubit;

  NotificationsBloc({
    required IrmaRepository repo,
  })  : _repo = repo,
        _credentialNotificationsCubit = CredentialStatusNotificationCubit(repo: repo)..loadCache(),
        super((NotificationsInitial()));

  @override
  Stream<NotificationsState> mapEventToState(NotificationsEvent event) async* {
    print('NotificationsBloc - mapEventToState event: $event');

    if (event is LoadCachedNotifications) {
      yield* _mapLoadCachedNotificationsToState();
    } else if (event is LoadNewNotifications) {
      yield* _mapLoadNewNotificationsToState();
    } else if (event is DeleteNotification) {
      yield* _mapDeleteNotificationToState(event);
    } else {
      throw UnimplementedError();
    }
  }

  Stream<NotificationsState> _mapDeleteNotificationToState(NotificationsEvent event) async* {
    yield NotificationsLoading();
    notifications.removeWhere((notification) => notification.key == (event as DeleteNotification).notificationKey);
    yield NotificationsLoaded(notifications);
  }

  Stream<NotificationsState> _mapLoadCachedNotificationsToState() async* {
    yield NotificationsLoading();

    final serializedNotifications = await _repo.preferences.getSerializedNotifications().first;
    final oldNotifications = _notificationsFromJson(serializedNotifications);

    notifications = oldNotifications;

    yield NotificationsLoaded(oldNotifications);
  }

  String _notificationsToJson(List<Notification> notifications) {
    // Map all notifications to json
    final mappedNotifications = notifications.map((notification) => notification.toJson()).toList();
    final mappedNotificationsJson = jsonEncode(mappedNotifications);

    return mappedNotificationsJson;
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

  Stream<NotificationsState> _mapLoadNewNotificationsToState() async* {
    yield NotificationsLoading();

    final newCredentialNotifications = _loadCredentialStatusNotifications();

    // TODO: Load notifications from other sources here

    final updatedNotifications = [
      ...newCredentialNotifications,
      ...notifications,
    ];

    // Write the notifications to the prefs
    final serializedNotifications = _notificationsToJson(updatedNotifications);
    await _repo.preferences.setSerializedNotifications(serializedNotifications);

    yield NotificationsLoaded(updatedNotifications);
  }

  Iterable<Notification> _loadCredentialStatusNotifications() {
    // Load the credential notifications in the cubit
    _credentialNotificationsCubit.loadCredentialStatusNotifications();

    // Pull the credential notifications from the cubit
    final newCredentialNotifications =
        (_credentialNotificationsCubit.state as CredentialStatusNotificationsLoaded).credentialStatusNotifications;

    // Clear the credential notifications in the cubit
    _credentialNotificationsCubit.clear();

    // Return the credential notifications
    // These are new status notifications that the user has not seen yet.
    return newCredentialNotifications;
  }
}

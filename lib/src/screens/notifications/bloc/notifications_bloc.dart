import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

import '../../../data/irma_repository.dart';
import '../../../widgets/credential_card/models/card_expiry_date.dart';
import '../models/credential_status_notification.dart';
import '../models/notification.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final IrmaRepository _repo;
  List<Notification> notifications = [];

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
    } else {
      throw UnimplementedError();
    }
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

    final List<Notification> updatedNotifications = notifications;

    final credentials = _repo.credentials.values;
    for (final cred in credentials) {
      // Check if a notification should be shown for this credential, and if so which type
      CredentialStatusNotificationType? notificationType;

      if (cred.revoked) {
        notificationType = CredentialStatusNotificationType.revoked;
      } else if (cred.expired) {
        notificationType = CredentialStatusNotificationType.expired;
      } else if (CardExpiryDate(cred.expires).expiresSoon) {
        notificationType = CredentialStatusNotificationType.expiringSoon;
      }

      // If a notification should be shown for this credential..
      if (notificationType != null) {
        bool shouldAddNewNotification = true;

        // Check if there is already a notification for this credential
        final CredentialStatusNotification? existingNotification =
            updatedNotifications.firstWhereOrNull((notification) {
          if (notification is CredentialStatusNotification) {
            return notification.credentialHash == cred.hashCode;
          }

          return false;
        }) as CredentialStatusNotification?;

        if (existingNotification != null) {
          // If the existing has a different type, remove the old one and add a new one later
          if (existingNotification.type != notificationType) {
            updatedNotifications.remove(existingNotification);
          } else {
            // If the existing has the same type, don't add a new one
            shouldAddNewNotification = false;
          }
        }

        if (shouldAddNewNotification) {
          updatedNotifications.add(
            CredentialStatusNotification(
              type: notificationType,
              credentialHash: cred.hashCode,
              credentialTypeId: cred.credentialType.fullId,
            ),
          );
        }
      }
    }

    // Write the updated notifications to the cache
    notifications = updatedNotifications;
    final serializedNotifications = _notificationsToJson(notifications);
    await _repo.preferences.setSerializedNotifications(serializedNotifications);

    final filteredNotifications = _filterNonSoftDeletedNotifications(notifications);
    yield NotificationsLoaded(filteredNotifications);
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

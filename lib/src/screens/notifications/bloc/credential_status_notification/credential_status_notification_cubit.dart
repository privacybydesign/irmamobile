import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../data/irma_repository.dart';
import '../../../../widgets/credential_card/models/card_expiry_date.dart';
import '../../models/credential_status_notification.dart';
import '../../models/notification.dart';

part 'credential_status_notification_state.dart';

class CredentialStatusNotificationCubit extends Cubit<CredentialStatusNotificationState> {
  final IrmaRepository _repo;

  CredentialStatusNotificationCubit({
    required IrmaRepository repo,
  })  : _repo = repo,
        super(CredentialStatusNotificationInitial());

  // Used to cache which credential status notifications already have been processed
  // The key of the map is the credential hash code and the value of the map is a list of the notification types that have been processed
  Map<int, List<CredentialStatusNotificationType>> credentialStatusNotifications = {};

  Future<void> loadCache() async {
    final serializedCredentialStatusNotifications =
        await _repo.preferences.getSerializedCredentialStatusNotifications().first;

    credentialStatusNotifications = _credentialStatusNotificationsFromJson(serializedCredentialStatusNotifications);
  }

  void loadCredentialStatusNotifications() {
    // Credential notifications
    final List<CredentialStatusNotification> newCredentialStatusNotifications = [];

    // Reusable function to process a credential status notification
    void processNotification(int credentialHashCode, CredentialStatusNotificationType type) {
      final notificationTypeAlreadyProcessed =
          credentialStatusNotifications[credentialHashCode]?.contains(CredentialStatusNotificationType.revoked) ??
              false;

      if (!notificationTypeAlreadyProcessed) {
        _updateCredentialStatusNotificationsCache(credentialHashCode, CredentialStatusNotificationType.revoked);
        newCredentialStatusNotifications.add(
          CredentialStatusNotification(
            credentialHash: credentialHashCode,
            type: CredentialStatusNotificationType.revoked,
          ),
        );
      }
    }

    for (final cred in _repo.credentials.values) {
      if (cred.revoked) {
        processNotification(
          cred.hashCode,
          CredentialStatusNotificationType.revoked,
        );
      } else if (cred.expired) {
        processNotification(
          cred.hashCode,
          CredentialStatusNotificationType.expired,
        );
      } else if (CardExpiryDate(cred.expires).expiresSoon) {
        processNotification(
          cred.hashCode,
          CredentialStatusNotificationType.expiringSoon,
        );
      }
    }

    //Map the CredentialStatusNotifications to generic Notifications
    final Iterable<Notification> newNotifications = newCredentialStatusNotifications.map<Notification>(
        (credStatusNotification) => Notification.fromCredentialStatusNotification(credStatusNotification));

    // Add the new notifications to the cache
    _writeCacheToPreferences();

    emit(CredentialStatusNotificationsLoaded(newNotifications));
  }

  String _credentialStatusNotificationsToJson() {
    // Map the map to a map that can be serialized to JSON
    // The keys are turned into a string and the enums are mapped to their index
    final Map<String, List<int>> mappedCredentialStatusNotifications = credentialStatusNotifications.map(
      (key, credentialStatusType) => MapEntry(
        key.toString(),
        credentialStatusType.map((e) => e.index).toList(),
      ),
    );

    // Encode the map to JSON
    final serializedCredentialStatusNotifications = jsonEncode(mappedCredentialStatusNotifications);

    return serializedCredentialStatusNotifications;
  }

  Map<int, List<CredentialStatusNotificationType>> _credentialStatusNotificationsFromJson(
      String serializedCredentialStatusNotifications) {
    credentialStatusNotifications = {};

    if (serializedCredentialStatusNotifications != '') {
      final Map<String, dynamic> decodedCredentialStatusNotification =
          jsonDecode(serializedCredentialStatusNotifications);

      credentialStatusNotifications = decodedCredentialStatusNotification.map(
        (key, value) => MapEntry(
          int.parse(key),
          (value as List)
              .map(
                (index) => CredentialStatusNotificationType.values[index],
              )
              .toList(),
        ),
      );
    }

    return credentialStatusNotifications;
  }

  void _writeCacheToPreferences() async {
    final String cacheJson = _credentialStatusNotificationsToJson();
    await _repo.preferences.setSerializedCredentialStatusNotifications(cacheJson);
  }

  void _updateCredentialStatusNotificationsCache(int credentialHashCode, CredentialStatusNotificationType type) {
    // Check if a map entry for this credential already exists
    if (credentialStatusNotifications[credentialHashCode] == null) {
      credentialStatusNotifications[credentialHashCode] = [];
    }

    // Add the notification type to the list of processed notifications for this credential
    credentialStatusNotifications[credentialHashCode]!.add(type);
  }

  void clear() => emit(CredentialStatusNotificationInitial());
}

part of 'credential_status_notification_cubit.dart';

abstract class CredentialStatusNotificationState extends Equatable {
  const CredentialStatusNotificationState();

  @override
  List<Object> get props => [];
}

class CredentialStatusNotificationInitial extends CredentialStatusNotificationState {}

class CredentialStatusNotificationsLoaded extends CredentialStatusNotificationState {
  const CredentialStatusNotificationsLoaded(this.credentialStatusNotifications);

  final Iterable<Notification> credentialStatusNotifications;

}

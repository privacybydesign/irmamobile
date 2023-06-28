import 'credential_status_notification.dart';

class Notification {
  final String title;
  final String message;
  final Function()? action;

  const Notification({
    required this.title,
    required this.message,
    this.action,
  });

  static Notification fromCredentialStatusNotification(CredentialStatusNotification credStatusNotification) {
    // TODO: Make this dynamic
    return Notification(
      title: 'Credential revoked',
      message: 'The credential ${credStatusNotification.credentialHash} has been revoked',
      action: () => throw UnimplementedError(),
    );
  }
}

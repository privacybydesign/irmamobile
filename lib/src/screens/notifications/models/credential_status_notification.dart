enum CredentialStatusNotificationType {
  revoked,
  expired,
  expiringSoon,
}

class CredentialStatusNotification {
  final int credentialHash;
  final CredentialStatusNotificationType type;

  CredentialStatusNotification({
    required this.credentialHash,
    required this.type,
  });
}

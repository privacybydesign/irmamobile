import "package:collection/collection.dart";

import "../../../models/log_entry.dart";
import "card_expiry_date.dart";

/// The expiry/validity state of a credential property (time-based or instance-based).
enum ExpireState { notExpired, almostExpired, expired }

/// Pre-computed display status for a [YiviCredentialCard].
///
/// Encapsulates all the expiry, revocation, and instance-count logic
/// so the card widget itself is a pure presentation component.
class CredentialCardStatus {
  final CardExpiryDate? expiryDate;
  final bool revoked;
  final int? instanceCount;
  final ExpireState timeExpireState;
  final ExpireState instanceExpireState;

  /// Whether the credential has any expired state (time or instance based).
  final bool isExpired;

  /// Whether the credential has any warning or error state (expiring soon or expired).
  final bool hasWarning;

  /// Whether the credential is fully valid (not expired, not revoked).
  final bool isValid;

  const CredentialCardStatus._({
    required this.expiryDate,
    required this.revoked,
    required this.instanceCount,
    required this.timeExpireState,
    required this.instanceExpireState,
    required this.isExpired,
    required this.hasWarning,
    required this.isValid,
  });

  factory CredentialCardStatus({
    int? expiryDateUnix,
    required bool revoked,
    required Map<CredentialFormat, int?> batchInstanceCountsRemaining,
    bool templateMode = false,
    int lowInstanceCountThreshold = 5,
  }) {
    final expiryDate = expiryDateUnix != null
        ? CardExpiryDate.fromUnix(expiryDateUnix)
        : null;

    final instanceCount = batchInstanceCountsRemaining.values.firstWhereOrNull(
      (c) => c != null,
    );

    final timeExpireState = _computeTimeExpireState(expiryDate);
    final instanceExpireState = _computeInstanceExpireState(
      instanceCount,
      lowInstanceCountThreshold,
    );

    final isExpired =
        !templateMode &&
        (timeExpireState == ExpireState.expired ||
            instanceExpireState == ExpireState.expired);

    final hasWarning =
        !templateMode &&
        (timeExpireState != ExpireState.notExpired ||
            instanceExpireState != ExpireState.notExpired);

    final isValid = !isExpired && !revoked;

    return CredentialCardStatus._(
      expiryDate: expiryDate,
      revoked: revoked,
      instanceCount: instanceCount,
      timeExpireState: timeExpireState,
      instanceExpireState: instanceExpireState,
      isExpired: isExpired,
      hasWarning: hasWarning,
      isValid: isValid,
    );
  }

  static ExpireState _computeTimeExpireState(CardExpiryDate? expiryDate) {
    if (expiryDate == null) return ExpireState.notExpired;
    if (expiryDate.expired) return ExpireState.expired;
    if (expiryDate.expiresSoon) return ExpireState.almostExpired;
    return ExpireState.notExpired;
  }

  static ExpireState _computeInstanceExpireState(
    int? instanceCount,
    int threshold,
  ) {
    if (instanceCount == null) return ExpireState.notExpired;
    if (instanceCount <= 0) return ExpireState.expired;
    if (instanceCount <= threshold) return ExpireState.almostExpired;
    return ExpireState.notExpired;
  }
}

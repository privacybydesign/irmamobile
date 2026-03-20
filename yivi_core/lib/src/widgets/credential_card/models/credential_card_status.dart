import "package:collection/collection.dart";

import "../../../models/log_entry.dart";
import "../../../models/translated_value.dart";
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

  /// The credential type identifier (e.g. "irma-demo.sidn-pbdf.email").
  final String? credentialId;

  /// The URL where this credential can be (re)obtained.
  final TranslatedValue? issueUrl;

  /// Whether the reobtain button should be shown:
  /// true when the credential has a valid issue URL and is expiring, expired, or revoked.
  final bool showReobtain;

  /// Whether the "not obtainable" information box should be shown:
  /// true when the credential has no valid issue URL and is not valid or is a template.
  final bool showNotObtainable;

  const CredentialCardStatus._({
    required this.expiryDate,
    required this.revoked,
    required this.instanceCount,
    required this.timeExpireState,
    required this.instanceExpireState,
    required this.isExpired,
    required this.hasWarning,
    required this.isValid,
    required this.credentialId,
    required this.issueUrl,
    required this.showReobtain,
    required this.showNotObtainable,
  });

  factory CredentialCardStatus({
    int? expiryDateUnix,
    required bool revoked,
    required Map<CredentialFormat, int?> batchInstanceCountsRemaining,
    bool templateMode = false,
    int lowInstanceCountThreshold = 5,
    String? credentialId,
    TranslatedValue? issueUrl,
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

    final hasValidIssueUrl =
        issueUrl != null && issueUrl.values.any((v) => v.isNotEmpty);
    final showReobtain = hasValidIssueUrl && (hasWarning || revoked);
    final showNotObtainable =
        !hasValidIssueUrl && (!isValid || templateMode);

    return CredentialCardStatus._(
      expiryDate: expiryDate,
      revoked: revoked,
      instanceCount: instanceCount,
      timeExpireState: timeExpireState,
      instanceExpireState: instanceExpireState,
      isExpired: isExpired,
      hasWarning: hasWarning,
      isValid: isValid,
      credentialId: credentialId,
      issueUrl: issueUrl,
      showReobtain: showReobtain,
      showNotObtainable: showNotObtainable,
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

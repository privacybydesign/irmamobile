import "card_expiry_date.dart";
import "credential_card_status.dart";

/// How a status line item asks for attention.
enum StatusTone { calm, warning, error }

enum StatusKind { validity, shares }

/// One item of a credential card's status line: validity or remaining shares.
class StatusLineItem {
  final StatusKind kind;
  final String translationKey;
  final Map<String, String> params;
  final StatusTone tone;

  /// Translation through `FlutterI18n.plural` with this count, instead of a
  /// plain translation.
  final int? pluralCount;

  const StatusLineItem({
    required this.kind,
    required this.translationKey,
    required this.tone,
    this.params = const {},
    this.pluralCount,
  });
}

const _prefix = "credential.status_line";

/// The status line's two items. [formatDate] turns the expiry date into text
/// in the app's language.
List<StatusLineItem> statusLineItems({
  required CardExpiryDate? expiryDate,
  required int? instanceCount,
  required ExpireState timeState,
  required ExpireState instanceState,
  required String Function(DateTime) formatDate,
}) {
  final date = expiryDate?.dateTime;
  final validity = switch ((date, timeState)) {
    (null, _) => const StatusLineItem(
      kind: StatusKind.validity,
      translationKey: "$_prefix.valid_indefinitely",
      tone: StatusTone.calm,
    ),
    (final d?, ExpireState.expired) => StatusLineItem(
      kind: StatusKind.validity,
      translationKey: "$_prefix.expired_on",
      params: {"date": formatDate(d)},
      tone: StatusTone.error,
    ),
    (_, ExpireState.almostExpired) => StatusLineItem(
      kind: StatusKind.validity,
      translationKey: "$_prefix.expires_in",
      pluralCount: expiryDate!.validDays.clamp(0, 1 << 30),
      tone: StatusTone.warning,
    ),
    (final d?, ExpireState.notExpired) => StatusLineItem(
      kind: StatusKind.validity,
      translationKey: "$_prefix.valid_until",
      params: {"date": formatDate(d)},
      tone: StatusTone.calm,
    ),
  };

  final shares = switch ((instanceCount, instanceState)) {
    (null, _) => const StatusLineItem(
      kind: StatusKind.shares,
      translationKey: "$_prefix.shares_unlimited",
      tone: StatusTone.calm,
    ),
    (_, ExpireState.expired) => const StatusLineItem(
      kind: StatusKind.shares,
      translationKey: "$_prefix.shares_none",
      tone: StatusTone.error,
    ),
    (final n?, ExpireState.almostExpired) => StatusLineItem(
      kind: StatusKind.shares,
      translationKey: "$_prefix.shares_few",
      params: {"count": "$n"},
      tone: StatusTone.warning,
    ),
    (final n?, ExpireState.notExpired) => StatusLineItem(
      kind: StatusKind.shares,
      translationKey: "$_prefix.shares_left",
      params: {"count": "$n"},
      tone: StatusTone.calm,
    ),
  };

  return [validity, shares];
}

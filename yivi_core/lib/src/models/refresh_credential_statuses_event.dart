import "package:json_annotation/json_annotation.dart";

import "event.dart";

part "refresh_credential_statuses_event.g.dart";

/// Asks irmago to re-fetch the Token Status Lists our credentials reference and
/// write back each one's status. Dispatch it via
/// `IrmaRepository.refreshCredentialStatuses`, which rate-limits it.
@JsonSerializable()
class RefreshCredentialStatusesEvent extends Event {
  RefreshCredentialStatusesEvent();

  factory RefreshCredentialStatusesEvent.fromJson(Map<String, dynamic> json) =>
      _$RefreshCredentialStatusesEventFromJson(json);
  Map<String, dynamic> toJson() => _$RefreshCredentialStatusesEventToJson(this);
}

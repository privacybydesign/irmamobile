import "package:json_annotation/json_annotation.dart";

import "event.dart";

part "refresh_credential_statuses_event.g.dart";

/// Dispatch via `IrmaRepository.refreshCredentialStatuses`, which rate-limits it.
@JsonSerializable()
class RefreshCredentialStatusesEvent extends Event implements BridgeEvent {
  @override
  String get wireName => "RefreshCredentialStatusesEvent";

  RefreshCredentialStatusesEvent();

  factory RefreshCredentialStatusesEvent.fromJson(Map<String, dynamic> json) =>
      _$RefreshCredentialStatusesEventFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$RefreshCredentialStatusesEventToJson(this);
}

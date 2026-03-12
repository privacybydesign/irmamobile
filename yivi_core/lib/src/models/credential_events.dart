import "package:json_annotation/json_annotation.dart";

import "event.dart";
import "log_entry.dart";

part "credential_events.g.dart";

@JsonSerializable(fieldRename: FieldRename.snake)
class DeleteCredentialEvent extends Event {
  DeleteCredentialEvent({required this.hashByFormat});

  final Map<CredentialFormat, String> hashByFormat;

  factory DeleteCredentialEvent.fromJson(Map<String, dynamic> json) =>
      _$DeleteCredentialEventFromJson(json);
  Map<String, dynamic> toJson() => _$DeleteCredentialEventToJson(this);
}

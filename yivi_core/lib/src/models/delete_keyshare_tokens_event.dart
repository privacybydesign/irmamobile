import "package:json_annotation/json_annotation.dart";

import "event.dart";

part "delete_keyshare_tokens_event.g.dart";

@JsonSerializable()
class DeleteKeyshareTokensEvent extends Event implements BridgeEvent {
  @override
  String get wireName => "DeleteKeyshareTokensEvent";

  DeleteKeyshareTokensEvent();

  factory DeleteKeyshareTokensEvent.fromJson(Map<String, dynamic> json) =>
      _$DeleteKeyshareTokensEventFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DeleteKeyshareTokensEventToJson(this);
}

import "package:json_annotation/json_annotation.dart";

import "event.dart";

part "update_schemes_event.g.dart";

@JsonSerializable()
class UpdateSchemesEvent extends Event implements BridgeEvent {
  @override
  String get wireName => "UpdateSchemesEvent";

  UpdateSchemesEvent();

  factory UpdateSchemesEvent.fromJson(Map<String, dynamic> json) =>
      _$UpdateSchemesEventFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$UpdateSchemesEventToJson(this);
}

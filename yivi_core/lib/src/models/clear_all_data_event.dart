import "package:json_annotation/json_annotation.dart";

import "event.dart";

part "clear_all_data_event.g.dart";

@JsonSerializable()
class ClearAllDataEvent extends Event implements BridgeEvent {
  @override
  String get wireName => "ClearAllDataEvent";

  ClearAllDataEvent();

  factory ClearAllDataEvent.fromJson(Map<String, dynamic> json) =>
      _$ClearAllDataEventFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ClearAllDataEventToJson(this);
}

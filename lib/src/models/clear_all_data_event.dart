import 'package:irmamobile/src/models/event.dart';
import 'package:json_annotation/json_annotation.dart';

part 'clear_all_data_event.g.dart';

@JsonSerializable(nullable: false)
class ClearAllDataEvent extends Event {
  ClearAllDataEvent();

  factory ClearAllDataEvent.fromJson(Map<String, dynamic> json) => _$ClearAllDataEventFromJson(json);
  Map<String, dynamic> toJson() => _$ClearAllDataEventToJson(this);
}

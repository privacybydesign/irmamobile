import 'package:irmamobile/src/models/event.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_ready_event.g.dart';

@JsonSerializable()
class AppReadyEvent extends Event {
  AppReadyEvent();

  factory AppReadyEvent.fromJson(Map<String, dynamic> json) => _$AppReadyEventFromJson(json);
  Map<String, dynamic> toJson() => _$AppReadyEventToJson(this);
}

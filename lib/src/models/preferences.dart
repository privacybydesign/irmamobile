import 'package:irmamobile/src/models/event.dart';
import 'package:json_annotation/json_annotation.dart';

part 'preferences.g.dart';

@JsonSerializable()
class SetCrashReportingPreferenceEvent extends Event {
  SetCrashReportingPreferenceEvent({this.enableCrashReporting});

  @JsonKey(name: 'EnableCrashReporting')
  bool enableCrashReporting;

  factory SetCrashReportingPreferenceEvent.fromJson(Map<String, dynamic> json) =>
      _$SetCrashReportingPreferenceEventFromJson(json);
  Map<String, dynamic> toJson() => _$SetCrashReportingPreferenceEventToJson(this);
}

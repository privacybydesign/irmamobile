import 'package:irmamobile/src/models/event.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_crash_reporting_preference.g.dart';

@JsonSerializable()
class SetCrashReportingPreferenceEvent extends Event {
  SetCrashReportingPreferenceEvent({required this.enableCrashReporting});

  @JsonKey(name: 'EnableCrashReporting')
  final bool enableCrashReporting;

  factory SetCrashReportingPreferenceEvent.fromJson(Map<String, dynamic> json) =>
      _$SetCrashReportingPreferenceEventFromJson(json);
  Map<String, dynamic> toJson() => _$SetCrashReportingPreferenceEventToJson(this);
}

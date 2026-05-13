import "package:json_annotation/json_annotation.dart";

import "event.dart";

part "set_crash_reporting_preference.g.dart";

@JsonSerializable(fieldRename: FieldRename.snake)
class SetCrashReportingPreferenceEvent extends Event {
  SetCrashReportingPreferenceEvent({required this.enableCrashReporting});

  final bool enableCrashReporting;

  factory SetCrashReportingPreferenceEvent.fromJson(
    Map<String, dynamic> json,
  ) => _$SetCrashReportingPreferenceEventFromJson(json);
  Map<String, dynamic> toJson() =>
      _$SetCrashReportingPreferenceEventToJson(this);
}

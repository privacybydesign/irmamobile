// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetCrashReportingPreferenceEvent _$SetCrashReportingPreferenceEventFromJson(Map<String, dynamic> json) {
  return SetCrashReportingPreferenceEvent(
    enableCrashReporting: json['EnableCrashReporting'] as bool,
  );
}

Map<String, dynamic> _$SetCrashReportingPreferenceEventToJson(SetCrashReportingPreferenceEvent instance) =>
    <String, dynamic>{
      'EnableCrashReporting': instance.enableCrashReporting,
    };

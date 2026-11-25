// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'native_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$AppReadyEventToJson(AppReadyEvent instance) =>
    <String, dynamic>{'locale': instance.locale};

Map<String, dynamic> _$SetLocaleEventToJson(SetLocaleEvent instance) =>
    <String, dynamic>{'locale': instance.locale};

AppReadyAckEvent _$AppReadyAckEventFromJson(Map<String, dynamic> json) =>
    AppReadyAckEvent(
      sessionIdBase: (json['session_id_base'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$AndroidSendToBackgroundEventToJson(
  AndroidSendToBackgroundEvent instance,
) => <String, dynamic>{};

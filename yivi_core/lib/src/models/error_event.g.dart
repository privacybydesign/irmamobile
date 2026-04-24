// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ErrorEvent _$ErrorEventFromJson(Map<String, dynamic> json) => ErrorEvent(
  exception: json['exception'] as String,
  stack: json['stack'] as String,
  fatal: json['fatal'] as bool,
);

Map<String, dynamic> _$ErrorEventToJson(ErrorEvent instance) =>
    <String, dynamic>{
      'exception': instance.exception,
      'stack': instance.stack,
      'fatal': instance.fatal,
    };

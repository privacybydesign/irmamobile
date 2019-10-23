// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enroll_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnrollEvent _$EnrollEventFromJson(Map<String, dynamic> json) {
  return EnrollEvent(
    email: json['Email'] as String,
    pin: json['Pin'] as String,
    language: json['Language'] as String,
  );
}

Map<String, dynamic> _$EnrollEventToJson(EnrollEvent instance) => <String, dynamic>{
      'Email': instance.email,
      'Pin': instance.pin,
      'Language': instance.language,
    };

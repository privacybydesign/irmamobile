// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CredentialsEvent _$CredentialsEventFromJson(Map<String, dynamic> json) {
  return CredentialsEvent(
    credentials: (json['Credentials'] as List).map((e) => Credential.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

Map<String, dynamic> _$CredentialsEventToJson(CredentialsEvent instance) => <String, dynamic>{
      'Credentials': instance.credentials,
    };

AppReadyEvent _$AppReadyEventFromJson(Map<String, dynamic> json) {
  return AppReadyEvent();
}

Map<String, dynamic> _$AppReadyEventToJson(AppReadyEvent instance) => <String, dynamic>{};

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

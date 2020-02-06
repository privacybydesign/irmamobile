// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enrollment_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnrollmentStatusEvent _$EnrollmentStatusEventFromJson(Map<String, dynamic> json) {
  return EnrollmentStatusEvent(
    enrolledSchemeManagerIds: (json['EnrolledSchemeManagerIds'] as List)?.map((e) => e as String)?.toList(),
    unenrolledSchemeManagerIds: (json['UnenrolledSchemeManagerIds'] as List)?.map((e) => e as String)?.toList(),
  );
}

Map<String, dynamic> _$EnrollmentStatusEventToJson(EnrollmentStatusEvent instance) => <String, dynamic>{
      'EnrolledSchemeManagerIds': instance.enrolledSchemeManagerIds,
      'UnenrolledSchemeManagerIds': instance.unenrolledSchemeManagerIds,
    };

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

EnrollmentFailureEvent _$EnrollmentFailureEventFromJson(Map<String, dynamic> json) {
  return EnrollmentFailureEvent(
    schemeManagerID: json['SchemeManagerID'] as String,
    error: json['Error'] == null ? null : SessionError.fromJson(json['Error'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$EnrollmentFailureEventToJson(EnrollmentFailureEvent instance) => <String, dynamic>{
      'SchemeManagerID': instance.schemeManagerID,
      'Error': instance.error,
    };

EnrollmentSuccessEvent _$EnrollmentSuccessEventFromJson(Map<String, dynamic> json) {
  return EnrollmentSuccessEvent(
    schemeManagerID: json['SchemeManagerID'] as String,
  );
}

Map<String, dynamic> _$EnrollmentSuccessEventToJson(EnrollmentSuccessEvent instance) => <String, dynamic>{
      'SchemeManagerID': instance.schemeManagerID,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enrollment_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnrollmentStatusEvent _$EnrollmentStatusEventFromJson(
  Map<String, dynamic> json,
) => EnrollmentStatusEvent(
  enrolledSchemeManagerIds:
      (json['enrolled_scheme_manager_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
  unenrolledSchemeManagerIds:
      (json['unenrolled_scheme_manager_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
);

Map<String, dynamic> _$EnrollmentStatusEventToJson(
  EnrollmentStatusEvent instance,
) => <String, dynamic>{
  'enrolled_scheme_manager_ids': instance.enrolledSchemeManagerIds,
  'unenrolled_scheme_manager_ids': instance.unenrolledSchemeManagerIds,
};

EnrollEvent _$EnrollEventFromJson(Map<String, dynamic> json) => EnrollEvent(
  email: json['email'] as String,
  pin: json['pin'] as String,
  language: json['language'] as String,
  schemeId: json['scheme_id'] as String,
);

Map<String, dynamic> _$EnrollEventToJson(EnrollEvent instance) =>
    <String, dynamic>{
      'email': instance.email,
      'pin': instance.pin,
      'language': instance.language,
      'scheme_id': instance.schemeId,
    };

EnrollmentFailureEvent _$EnrollmentFailureEventFromJson(
  Map<String, dynamic> json,
) => EnrollmentFailureEvent(
  schemeManagerID: json['scheme_manager_id'] as String,
  error: SessionError.fromJson(json['error'] as Map<String, dynamic>),
);

Map<String, dynamic> _$EnrollmentFailureEventToJson(
  EnrollmentFailureEvent instance,
) => <String, dynamic>{
  'scheme_manager_id': instance.schemeManagerID,
  'error': instance.error,
};

EnrollmentSuccessEvent _$EnrollmentSuccessEventFromJson(
  Map<String, dynamic> json,
) => EnrollmentSuccessEvent(
  schemeManagerID: json['scheme_manager_id'] as String,
);

Map<String, dynamic> _$EnrollmentSuccessEventToJson(
  EnrollmentSuccessEvent instance,
) => <String, dynamic>{'scheme_manager_id': instance.schemeManagerID};

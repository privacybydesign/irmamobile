// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enrollment_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnrollmentStatus _$EnrollmentStatusFromJson(Map<String, dynamic> json) {
  return EnrollmentStatus(
    enrolledSchemeManagers: (json['EnrolledSchemeManagerIds'] as List).map((e) => e as String).toList(),
    unenrolledSchemeManagers: (json['UnenrolledSchemeManagerIds'] as List).map((e) => e as String).toList(),
  );
}

Map<String, dynamic> _$EnrollmentStatusToJson(EnrollmentStatus instance) => <String, dynamic>{
      'EnrolledSchemeManagerIds': instance.enrolledSchemeManagers,
      'UnenrolledSchemeManagerIds': instance.unenrolledSchemeManagers,
    };

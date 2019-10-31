import 'package:json_annotation/json_annotation.dart';

part 'enrollment_status.g.dart';

@JsonSerializable(nullable: false)
class EnrollmentStatus {
  EnrollmentStatus({
    this.enrolledSchemeManagers,
    this.unenrolledSchemeManagers,
  });

  factory EnrollmentStatus.empty() {
    return EnrollmentStatus(enrolledSchemeManagers: [], unenrolledSchemeManagers: []);
  }

  @JsonKey(name: 'EnrolledSchemeManagerIds')
  final List<String> enrolledSchemeManagers;

  @JsonKey(name: 'UnenrolledSchemeManagerIds')
  final List<String> unenrolledSchemeManagers;

  bool isEnrolled() => enrolledSchemeManagers.length > 0;
  bool isUnenrolled() => !isEnrolled() && unenrolledSchemeManagers.length > 0;
  bool isEmpty() => enrolledSchemeManagers.length == 0 && unenrolledSchemeManagers.length == 0;

  factory EnrollmentStatus.fromJson(Map<String, dynamic> json) => _$EnrollmentStatusFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollmentStatusToJson(this);
}

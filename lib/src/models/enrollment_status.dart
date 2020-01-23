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

  bool isEnrolled() => enrolledSchemeManagers.isNotEmpty;
  bool isUnenrolled() => !isEnrolled() && unenrolledSchemeManagers.isNotEmpty;
  bool isEmpty() => enrolledSchemeManagers.isEmpty && unenrolledSchemeManagers.isEmpty;

  factory EnrollmentStatus.fromJson(Map<String, dynamic> json) => _$EnrollmentStatusFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollmentStatusToJson(this);
}

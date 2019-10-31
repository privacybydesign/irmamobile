import 'package:json_annotation/json_annotation.dart';

part 'enrollment_status.g.dart';

@JsonSerializable(nullable: false)
class EnrollmentStatus {
  EnrollmentStatus({
    this.enrolledSchemeManagers,
    this.unenrolledSchemeManagers,
  });

  @JsonKey(name: 'EnrolledSchemeManagerIds')
  final List<String> enrolledSchemeManagers;

  @JsonKey(name: 'UnenrolledSchemeManagerIds')
  final List<String> unenrolledSchemeManagers;

  factory EnrollmentStatus.fromJson(Map<String, dynamic> json) => _$EnrollmentStatusFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollmentStatusToJson(this);
}

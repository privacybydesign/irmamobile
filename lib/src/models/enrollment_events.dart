import 'package:irmamobile/src/models/enrollment_status.dart';
import 'package:irmamobile/src/models/event.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:json_annotation/json_annotation.dart';

part 'enrollment_events.g.dart';

@JsonSerializable()
class EnrollmentStatusEvent extends Event {
  EnrollmentStatusEvent({this.enrolledSchemeManagerIds, this.unenrolledSchemeManagerIds});

  @JsonKey(name: 'EnrolledSchemeManagerIds')
  List<String> enrolledSchemeManagerIds;

  @JsonKey(name: 'UnenrolledSchemeManagerIds')
  List<String> unenrolledSchemeManagerIds;

  factory EnrollmentStatusEvent.fromJson(Map<String, dynamic> json) => _$EnrollmentStatusEventFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollmentStatusEventToJson(this);

  EnrollmentStatus get enrollmentStatus =>
      enrolledSchemeManagerIds.isNotEmpty ? EnrollmentStatus.enrolled : EnrollmentStatus.unenrolled;
}

@JsonSerializable()
class EnrollEvent extends Event {
  EnrollEvent({this.email, this.pin, this.language});

  @JsonKey(name: 'Email')
  String email;

  @JsonKey(name: 'Pin')
  String pin;

  @JsonKey(name: 'Language')
  String language;

  factory EnrollEvent.fromJson(Map<String, dynamic> json) => _$EnrollEventFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollEventToJson(this);
}

class EnrollmentEvent extends Event {}

@JsonSerializable()
class EnrollmentFailureEvent extends EnrollmentEvent {
  EnrollmentFailureEvent({
    this.schemeManagerID,
    this.error,
  });

  @JsonKey(name: 'SchemeManagerID')
  String schemeManagerID;

  @JsonKey(name: 'Error')
  SessionError error;

  factory EnrollmentFailureEvent.fromJson(Map<String, dynamic> json) => _$EnrollmentFailureEventFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollmentFailureEventToJson(this);
}

@JsonSerializable()
class EnrollmentSuccessEvent extends EnrollmentEvent {
  EnrollmentSuccessEvent({this.schemeManagerID});

  @JsonKey(name: 'SchemeManagerID')
  String schemeManagerID;

  factory EnrollmentSuccessEvent.fromJson(Map<String, dynamic> json) => _$EnrollmentSuccessEventFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollmentSuccessEventToJson(this);
}

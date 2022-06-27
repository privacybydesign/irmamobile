import 'package:irmamobile/src/models/event.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:json_annotation/json_annotation.dart';

part 'enrollment_events.g.dart';

@JsonSerializable()
class EnrollmentStatusEvent extends Event {
  EnrollmentStatusEvent({required this.enrolledSchemeManagerIds, required this.unenrolledSchemeManagerIds});

  @JsonKey(name: 'EnrolledSchemeManagerIds')
  final List<String> enrolledSchemeManagerIds;

  @JsonKey(name: 'UnenrolledSchemeManagerIds')
  final List<String> unenrolledSchemeManagerIds;

  factory EnrollmentStatusEvent.fromJson(Map<String, dynamic> json) => _$EnrollmentStatusEventFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollmentStatusEventToJson(this);
}

@JsonSerializable()
class EnrollEvent extends Event {
  EnrollEvent({
    required this.email,
    required this.pin,
    required this.language,
    required this.schemeId,
  });

  @JsonKey(name: 'Email')
  final String email;

  @JsonKey(name: 'Pin')
  final String pin;

  @JsonKey(name: 'Language')
  final String language;

  @JsonKey(name: 'SchemeID')
  final String schemeId;

  factory EnrollEvent.fromJson(Map<String, dynamic> json) => _$EnrollEventFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollEventToJson(this);
}

class EnrollmentEvent extends Event {}

@JsonSerializable()
class EnrollmentFailureEvent extends EnrollmentEvent {
  EnrollmentFailureEvent({
    required this.schemeManagerID,
    required this.error,
  });

  @JsonKey(name: 'SchemeManagerID')
  final String schemeManagerID;

  @JsonKey(name: 'Error')
  final SessionError error;

  factory EnrollmentFailureEvent.fromJson(Map<String, dynamic> json) => _$EnrollmentFailureEventFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollmentFailureEventToJson(this);
}

@JsonSerializable()
class EnrollmentSuccessEvent extends EnrollmentEvent {
  EnrollmentSuccessEvent({required this.schemeManagerID});

  @JsonKey(name: 'SchemeManagerID')
  final String schemeManagerID;

  factory EnrollmentSuccessEvent.fromJson(Map<String, dynamic> json) => _$EnrollmentSuccessEventFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollmentSuccessEventToJson(this);
}

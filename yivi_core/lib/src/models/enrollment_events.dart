import "package:json_annotation/json_annotation.dart";

import "event.dart";
import "session.dart";

part "enrollment_events.g.dart";

@JsonSerializable(fieldRename: FieldRename.snake)
class EnrollmentStatusEvent extends Event {
  EnrollmentStatusEvent({
    required this.enrolledSchemeManagerIds,
    required this.unenrolledSchemeManagerIds,
  });

  final List<String> enrolledSchemeManagerIds;

  final List<String> unenrolledSchemeManagerIds;

  factory EnrollmentStatusEvent.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentStatusEventFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollmentStatusEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class EnrollEvent extends Event {
  EnrollEvent({
    required this.email,
    required this.pin,
    required this.language,
    required this.schemeId,
  });

  final String email;

  final String pin;

  final String language;

  final String schemeId;

  factory EnrollEvent.fromJson(Map<String, dynamic> json) =>
      _$EnrollEventFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollEventToJson(this);
}

class EnrollmentEvent extends Event {}

@JsonSerializable(fieldRename: FieldRename.snake)
class EnrollmentFailureEvent extends EnrollmentEvent {
  EnrollmentFailureEvent({required this.schemeManagerID, required this.error});

  @JsonKey(name: "scheme_manager_id")
  final String schemeManagerID;

  final SessionError error;

  factory EnrollmentFailureEvent.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentFailureEventFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollmentFailureEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class EnrollmentSuccessEvent extends EnrollmentEvent {
  EnrollmentSuccessEvent({required this.schemeManagerID});

  @JsonKey(name: "scheme_manager_id")
  final String schemeManagerID;

  factory EnrollmentSuccessEvent.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentSuccessEventFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollmentSuccessEventToJson(this);
}

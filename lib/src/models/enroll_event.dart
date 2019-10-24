import 'package:json_annotation/json_annotation.dart';

part 'enroll_event.g.dart';

@JsonSerializable(nullable: false)
class EnrollEvent {
  EnrollEvent({
    this.email,
    this.pin,
    this.language,
  });

  @JsonKey(name: 'Email')
  final String email;

  @JsonKey(name: 'Pin')
  final String pin;

  @JsonKey(name: 'Language')
  final String language;

  factory EnrollEvent.fromJson(Map<String, dynamic> json) => _$EnrollEventFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollEventToJson(this);
}

import 'package:irmamobile/src/models/credential.dart';
import 'package:json_annotation/json_annotation.dart';

part 'events.g.dart';

abstract class BridgeableEvent {}

@JsonSerializable(nullable: false)
class CredentialsEvent {
  CredentialsEvent({this.credentials});

  @JsonKey(name: 'Credentials')
  final List<Credential> credentials;

  factory CredentialsEvent.fromJson(Map<String, dynamic> json) => _$CredentialsEventFromJson(json);
  Map<String, dynamic> toJson() => _$CredentialsEventToJson(this);
}

@JsonSerializable(nullable: false)
class AppReadyEvent extends BridgeableEvent {
  AppReadyEvent();

  factory AppReadyEvent.fromJson(Map<String, dynamic> json) => _$AppReadyEventFromJson(json);
  Map<String, dynamic> toJson() => _$AppReadyEventToJson(this);
}

@JsonSerializable(nullable: false)
class EnrollEvent extends BridgeableEvent {
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

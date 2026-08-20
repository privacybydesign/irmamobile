import "package:json_annotation/json_annotation.dart";

import "event.dart";
import "session.dart";

part "authentication_events.g.dart";

abstract class AuthenticationEvent extends Event {}

@JsonSerializable(fieldRename: FieldRename.snake)
class AuthenticateEvent extends AuthenticationEvent {
  final String pin;

  final String schemeId;

  AuthenticateEvent({required this.pin, required this.schemeId});
  factory AuthenticateEvent.fromJson(Map<String, dynamic> json) =>
      _$AuthenticateEventFromJson(json);
  Map<String, dynamic> toJson() => _$AuthenticateEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class AuthenticationSuccessEvent extends AuthenticationEvent {
  AuthenticationSuccessEvent();

  factory AuthenticationSuccessEvent.fromJson(Map<String, dynamic> json) =>
      _$AuthenticationSuccessEventFromJson(json);
  Map<String, dynamic> toJson() => _$AuthenticationSuccessEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class AuthenticationFailedEvent extends AuthenticationEvent {
  final int remainingAttempts;

  final int blockedDuration;

  AuthenticationFailedEvent({
    required this.remainingAttempts,
    required this.blockedDuration,
  });
  factory AuthenticationFailedEvent.fromJson(Map<String, dynamic> json) =>
      _$AuthenticationFailedEventFromJson(json);
  Map<String, dynamic> toJson() => _$AuthenticationFailedEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class AuthenticationErrorEvent extends AuthenticationEvent {
  final SessionError error;

  AuthenticationErrorEvent({required this.error});
  factory AuthenticationErrorEvent.fromJson(Map<String, dynamic> json) =>
      _$AuthenticationErrorEventFromJson(json);
  Map<String, dynamic> toJson() => _$AuthenticationErrorEventToJson(this);
}

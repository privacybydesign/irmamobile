import 'package:json_annotation/json_annotation.dart';

import 'event.dart';
import 'session.dart';

part 'authentication_events.g.dart';

abstract class AuthenticationEvent extends Event {}

@JsonSerializable()
class AuthenticateEvent extends AuthenticationEvent {
  @JsonKey(name: "Pin")
  final String pin;

  @JsonKey(name: "SchemeID")
  final String schemeId;

  AuthenticateEvent({required this.pin, required this.schemeId});
  factory AuthenticateEvent.fromJson(Map<String, dynamic> json) => _$AuthenticateEventFromJson(json);
  Map<String, dynamic> toJson() => _$AuthenticateEventToJson(this);
}

@JsonSerializable()
class AuthenticationSuccessEvent extends AuthenticationEvent {
  AuthenticationSuccessEvent();

  factory AuthenticationSuccessEvent.fromJson(Map<String, dynamic> json) => _$AuthenticationSuccessEventFromJson(json);
  Map<String, dynamic> toJson() => _$AuthenticationSuccessEventToJson(this);
}

@JsonSerializable()
class AuthenticationFailedEvent extends AuthenticationEvent {
  @JsonKey(name: "RemainingAttempts")
  final int remainingAttempts;

  @JsonKey(name: "BlockedDuration")
  final int blockedDuration;

  AuthenticationFailedEvent({required this.remainingAttempts, required this.blockedDuration});
  factory AuthenticationFailedEvent.fromJson(Map<String, dynamic> json) => _$AuthenticationFailedEventFromJson(json);
  Map<String, dynamic> toJson() => _$AuthenticationFailedEventToJson(this);
}

@JsonSerializable()
class AuthenticationErrorEvent extends AuthenticationEvent {
  @JsonKey(name: "Error")
  final SessionError error;

  AuthenticationErrorEvent({required this.error});
  factory AuthenticationErrorEvent.fromJson(Map<String, dynamic> json) => _$AuthenticationErrorEventFromJson(json);
  Map<String, dynamic> toJson() => _$AuthenticationErrorEventToJson(this);
}

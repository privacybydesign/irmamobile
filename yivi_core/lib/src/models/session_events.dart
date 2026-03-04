import "package:flutter/foundation.dart";
import "package:json_annotation/json_annotation.dart";

import "attribute.dart";
import "event.dart";
import "session.dart";

part "session_events.g.dart";

abstract class SessionEvent extends Event {
  SessionEvent(this.sessionID);

  @JsonKey(name: "session_id")
  final int sessionID;
}

@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class NewSessionEvent extends SessionEvent {
  // This counter is used to give each session a unique number to correlate events
  // We start at some arbitrary point above zero
  static int sessionIDCounter = 42;

  NewSessionEvent({
    @visibleForTesting int? sessionID,
    required this.request,
    this.previouslyLaunchedCredentials = const <String>{},
  }) : super(sessionID ?? sessionIDCounter++);

  final SessionPointer request;

  // Id's of the credentials that the user tried to obtain from the credential store
  // or by reobtaining credentials from the data tab
  final Set<String> previouslyLaunchedCredentials;

  Map<String, dynamic> toJson() => _$NewSessionEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RespondPreAuthorizedCodeFlowPermissionEvent extends SessionEvent {
  RespondPreAuthorizedCodeFlowPermissionEvent({
    required int sessionID,
    required this.proceed,
    this.transactionCode,
  }) : super(sessionID);

  final bool proceed;

  @JsonKey(required: false)
  final String? transactionCode;

  factory RespondPreAuthorizedCodeFlowPermissionEvent.fromJson(
    Map<String, dynamic> json,
  ) => _$RespondPreAuthorizedCodeFlowPermissionEventFromJson(json);
  Map<String, dynamic> toJson() =>
      _$RespondPreAuthorizedCodeFlowPermissionEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RespondAuthorizationCodeEvent extends SessionEvent {
  RespondAuthorizationCodeEvent({
    required int sessionID,
    required this.proceed,
    required this.code,
  }) : super(sessionID);

  final bool proceed;

  final String code;

  factory RespondAuthorizationCodeEvent.fromJson(Map<String, dynamic> json) =>
      _$RespondAuthorizationCodeEventFromJson(json);
  Map<String, dynamic> toJson() => _$RespondAuthorizationCodeEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RespondTokenEvent extends SessionEvent {
  RespondTokenEvent({
    required int sessionID,
    required this.proceed,
    required this.accessToken,
    this.refreshToken,
  }) : super(sessionID);

  final bool proceed;

  final String accessToken;

  final String? refreshToken;

  factory RespondTokenEvent.fromJson(Map<String, dynamic> json) =>
      _$RespondTokenEventFromJson(json);
  Map<String, dynamic> toJson() => _$RespondTokenEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RespondPermissionEvent extends SessionEvent {
  RespondPermissionEvent({
    required int sessionID,
    required this.proceed,
    required this.disclosureChoices,
  }) : super(sessionID);

  final bool proceed;

  final List<List<AttributeIdentifier>> disclosureChoices;

  factory RespondPermissionEvent.fromJson(Map<String, dynamic> json) =>
      _$RespondPermissionEventFromJson(json);
  Map<String, dynamic> toJson() => _$RespondPermissionEventToJson(this);
}

class ContinueToIssuanceEvent extends SessionEvent {
  final List<List<AttributeIdentifier>> disclosureChoices;

  ContinueToIssuanceEvent({
    required int sessionID,
    required this.disclosureChoices,
  }) : super(sessionID);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RespondPinEvent extends SessionEvent {
  RespondPinEvent({required int sessionID, required this.proceed, this.pin})
    : super(sessionID);

  final bool proceed;

  final String? pin;

  factory RespondPinEvent.fromJson(Map<String, dynamic> json) =>
      _$RespondPinEventFromJson(json);
  Map<String, dynamic> toJson() => _$RespondPinEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class DismissSessionEvent extends SessionEvent {
  DismissSessionEvent({required int sessionID}) : super(sessionID);

  factory DismissSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$DismissSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$DismissSessionEventToJson(this);
}

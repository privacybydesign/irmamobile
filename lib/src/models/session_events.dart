import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';

import 'attribute.dart';
import 'credentials.dart';
import 'event.dart';
import 'session.dart';
import 'translated_value.dart';

part 'session_events.g.dart';

abstract class SessionEvent extends Event {
  SessionEvent(this.sessionID);

  @JsonKey(name: 'SessionID')
  final int sessionID;
}

@JsonSerializable(createFactory: false)
class NewSessionEvent extends SessionEvent {
  // This counter is used to give each session a unique number to correlate events
  // We start at some arbitrary point above zero
  static int sessionIDCounter = 42;

  NewSessionEvent({
    @visibleForTesting int? sessionID,
    required this.request,
    this.launchedCredentials = const <String>{},
  }) : super(sessionID ?? sessionIDCounter++);

  @JsonKey(name: 'Request')
  final SessionPointer request;

  // Id's of the credentials that the user tried to obtain from the credential store
  // or by reobtaining credentials from the data tab
  final Set<String> launchedCredentials;

  Map<String, dynamic> toJson() => _$NewSessionEventToJson(this);
}

@JsonSerializable()
class RespondPermissionEvent extends SessionEvent {
  RespondPermissionEvent({
    required int sessionID,
    required this.proceed,
    required this.disclosureChoices,
  }) : super(sessionID);

  @JsonKey(name: 'Proceed')
  final bool proceed;

  @JsonKey(name: 'DisclosureChoices')
  final List<List<AttributeIdentifier>> disclosureChoices;

  factory RespondPermissionEvent.fromJson(Map<String, dynamic> json) => _$RespondPermissionEventFromJson(json);
  Map<String, dynamic> toJson() => _$RespondPermissionEventToJson(this);
}

class ContinueToIssuanceEvent extends SessionEvent {
  final List<List<AttributeIdentifier>> disclosureChoices;

  ContinueToIssuanceEvent({required int sessionID, required this.disclosureChoices}) : super(sessionID);
}

@JsonSerializable()
class RespondPinEvent extends SessionEvent {
  RespondPinEvent({required int sessionID, required this.proceed, this.pin}) : super(sessionID);

  @JsonKey(name: 'Proceed')
  final bool proceed;

  @JsonKey(name: 'Pin')
  final String? pin;

  factory RespondPinEvent.fromJson(Map<String, dynamic> json) => _$RespondPinEventFromJson(json);
  Map<String, dynamic> toJson() => _$RespondPinEventToJson(this);
}

@JsonSerializable()
class DismissSessionEvent extends SessionEvent {
  DismissSessionEvent({required int sessionID}) : super(sessionID);

  factory DismissSessionEvent.fromJson(Map<String, dynamic> json) => _$DismissSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$DismissSessionEventToJson(this);
}

@JsonSerializable()
class StatusUpdateSessionEvent extends SessionEvent {
  StatusUpdateSessionEvent({required int sessionID, required this.action, required this.status}) : super(sessionID);

  @JsonKey(name: 'Action')
  final String action;

  @JsonKey(name: 'Status')
  final String status;

  factory StatusUpdateSessionEvent.fromJson(Map<String, dynamic> json) => _$StatusUpdateSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$StatusUpdateSessionEventToJson(this);
}

@JsonSerializable()
class ClientReturnURLSetSessionEvent extends SessionEvent {
  ClientReturnURLSetSessionEvent({required int sessionID, required this.clientReturnURL}) : super(sessionID);

  @JsonKey(name: 'ClientReturnURL')
  final String clientReturnURL;

  factory ClientReturnURLSetSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$ClientReturnURLSetSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$ClientReturnURLSetSessionEventToJson(this);
}

@JsonSerializable()
class SuccessSessionEvent extends SessionEvent {
  SuccessSessionEvent({required int sessionID}) : super(sessionID);

  factory SuccessSessionEvent.fromJson(Map<String, dynamic> json) => _$SuccessSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$SuccessSessionEventToJson(this);
}

@JsonSerializable()
class FailureSessionEvent extends SessionEvent {
  FailureSessionEvent({
    required int sessionID,
    required this.error,
  }) : super(sessionID);

  @JsonKey(name: 'Error')
  final SessionError error;

  factory FailureSessionEvent.fromJson(Map<String, dynamic> json) => _$FailureSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$FailureSessionEventToJson(this);
}

@JsonSerializable()
class CanceledSessionEvent extends SessionEvent {
  CanceledSessionEvent({required int sessionID}) : super(sessionID);

  factory CanceledSessionEvent.fromJson(Map<String, dynamic> json) => _$CanceledSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$CanceledSessionEventToJson(this);
}

@JsonSerializable()
class RequestIssuancePermissionSessionEvent extends SessionEvent {
  RequestIssuancePermissionSessionEvent({
    required int sessionID,
    required this.serverName,
    required this.satisfiable,
    required this.issuedCredentials,
    this.disclosuresLabels,
    this.disclosuresCandidates = const [],
  }) : super(sessionID);

  @JsonKey(name: 'ServerName')
  final RequestorInfo serverName;

  @JsonKey(name: 'Satisfiable')
  final bool satisfiable;

  @JsonKey(name: 'IssuedCredentials')
  final List<RawCredential> issuedCredentials;

  @JsonKey(name: 'DisclosuresLabels')
  final Map<int, TranslatedValue>? disclosuresLabels;

  @JsonKey(name: 'DisclosuresCandidates')
  final List<List<List<DisclosureCandidate>>> disclosuresCandidates;

  factory RequestIssuancePermissionSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$RequestIssuancePermissionSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$RequestIssuancePermissionSessionEventToJson(this);
}

@JsonSerializable()
class RequestVerificationPermissionSessionEvent extends SessionEvent {
  RequestVerificationPermissionSessionEvent({
    required int sessionID,
    required this.serverName,
    required this.satisfiable,
    required this.disclosuresCandidates,
    required this.isSignatureSession,
    this.disclosuresLabels,
    this.signedMessage,
  }) : super(sessionID);

  @JsonKey(name: 'ServerName')
  final RequestorInfo serverName;

  @JsonKey(name: 'Satisfiable')
  final bool satisfiable;

  @JsonKey(name: 'DisclosuresLabels')
  final Map<int, TranslatedValue>? disclosuresLabels;

  @JsonKey(name: 'DisclosuresCandidates')
  final List<List<List<DisclosureCandidate>>> disclosuresCandidates;

  @JsonKey(name: 'IsSignatureSession')
  final bool isSignatureSession;

  @JsonKey(name: 'SignedMessage')
  final String? signedMessage;

  factory RequestVerificationPermissionSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$RequestVerificationPermissionSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$RequestVerificationPermissionSessionEventToJson(this);
}

@JsonSerializable()
class RequestPinSessionEvent extends SessionEvent {
  RequestPinSessionEvent({required int sessionID, required this.remainingAttempts}) : super(sessionID);

  @JsonKey(name: 'RemainingAttempts')
  final int remainingAttempts;

  factory RequestPinSessionEvent.fromJson(Map<String, dynamic> json) => _$RequestPinSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$RequestPinSessionEventToJson(this);
}

@JsonSerializable()
class PairingRequiredSessionEvent extends SessionEvent {
  PairingRequiredSessionEvent({required int sessionID, required this.pairingCode}) : super(sessionID);

  @JsonKey(name: 'PairingCode')
  final String pairingCode;

  factory PairingRequiredSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$PairingRequiredSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$PairingRequiredSessionEventToJson(this);
}

@JsonSerializable()
class KeyshareEnrollmentMissingSessionEvent extends SessionEvent {
  KeyshareEnrollmentMissingSessionEvent({required int sessionID, required this.schemeManagerID}) : super(sessionID);

  @JsonKey(name: 'SchemeManagerID')
  final String schemeManagerID;

  factory KeyshareEnrollmentMissingSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$KeyshareEnrollmentMissingSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$KeyshareEnrollmentMissingSessionEventToJson(this);
}

@JsonSerializable()
class KeyshareEnrollmentDeletedSessionEvent extends SessionEvent {
  KeyshareEnrollmentDeletedSessionEvent({required int sessionID, required this.schemeManagerID}) : super(sessionID);

  @JsonKey(name: 'SchemeManagerID')
  final String schemeManagerID;

  factory KeyshareEnrollmentDeletedSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$KeyshareEnrollmentDeletedSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$KeyshareEnrollmentDeletedSessionEventToJson(this);
}

@JsonSerializable()
class KeyshareBlockedSessionEvent extends SessionEvent {
  KeyshareBlockedSessionEvent({
    required int sessionID,
    required this.schemeManagerID,
    required this.duration,
  }) : super(sessionID);

  @JsonKey(name: 'SchemeManagerID')
  final String schemeManagerID;

  @JsonKey(name: 'Duration')
  final int duration;

  factory KeyshareBlockedSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$KeyshareBlockedSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$KeyshareBlockedSessionEventToJson(this);
}

@JsonSerializable()
class KeyshareEnrollmentIncompleteSessionEvent extends SessionEvent {
  KeyshareEnrollmentIncompleteSessionEvent({required int sessionID, required this.schemeManagerID}) : super(sessionID);

  @JsonKey(name: 'SchemeManagerID')
  final String schemeManagerID;

  factory KeyshareEnrollmentIncompleteSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$KeyshareEnrollmentIncompleteSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$KeyshareEnrollmentIncompleteSessionEventToJson(this);
}

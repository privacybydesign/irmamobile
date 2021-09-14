import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/event.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:json_annotation/json_annotation.dart';

part 'session_events.g.dart';

abstract class SessionEvent extends Event {
  // The sessionID is not always known when constructing the class.
  // However, we need a sessionID to be present for a valid SessionEvent.
  // Therefore, we now check this at runtime by making the sessionID
  // 'late final' and by adding extra json annotations.
  // It might be good to re-consider the initialization of sessionID in the future,
  // such that it is known at construction time. Then we would not
  // have to rely on runtime checks.
  SessionEvent(int? sessionID) {
    if (sessionID != null) this.sessionID = sessionID;
  }

  @JsonKey(name: 'SessionID', required: true, disallowNullValue: true)
  late final int sessionID;
}

@JsonSerializable()
class NewSessionEvent extends SessionEvent {
  // This counter is used to give each session a unique number to correlate events
  // We start at some arbitrary point above zero
  static int sessionIDCounter = 42;

  NewSessionEvent({int? sessionID, required this.request, this.inAppCredential = ''}) : super(sessionID) {
    if (sessionID == null) this.sessionID = sessionIDCounter++;
  }

  @JsonKey(name: 'Request')
  final SessionPointer request;

  // Which credential's issue page, if any relevant, was last opened with the in-app browser
  final String inAppCredential;

  factory NewSessionEvent.fromJson(Map<String, dynamic> json) => _$NewSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$NewSessionEventToJson(this);
}

@JsonSerializable()
class RespondPermissionEvent extends SessionEvent {
  RespondPermissionEvent({
    int? sessionID,
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
  ContinueToIssuanceEvent({int? sessionID}) : super(sessionID);
}

@JsonSerializable()
class RespondPinEvent extends SessionEvent {
  RespondPinEvent({int? sessionID, required this.proceed, this.pin}) : super(sessionID);

  @JsonKey(name: 'Proceed')
  final bool proceed;

  @JsonKey(name: 'Pin')
  final String? pin;

  factory RespondPinEvent.fromJson(Map<String, dynamic> json) => _$RespondPinEventFromJson(json);
  Map<String, dynamic> toJson() => _$RespondPinEventToJson(this);
}

class DisclosureChoiceUpdateSessionEvent extends SessionEvent {
  final int disconIndex;
  final int conIndex;

  DisclosureChoiceUpdateSessionEvent({
    int? sessionID,
    required this.disconIndex,
    required this.conIndex,
  }) : super(sessionID);
}

@JsonSerializable()
class DismissSessionEvent extends SessionEvent {
  DismissSessionEvent({int? sessionID}) : super(sessionID);

  factory DismissSessionEvent.fromJson(Map<String, dynamic> json) => _$DismissSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$DismissSessionEventToJson(this);
}

@JsonSerializable()
class StatusUpdateSessionEvent extends SessionEvent {
  StatusUpdateSessionEvent({int? sessionID, required this.action, required this.status}) : super(sessionID);

  @JsonKey(name: 'Action')
  final String action;

  @JsonKey(name: 'Status')
  final String status;

  factory StatusUpdateSessionEvent.fromJson(Map<String, dynamic> json) => _$StatusUpdateSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$StatusUpdateSessionEventToJson(this);
}

@JsonSerializable()
class ClientReturnURLSetSessionEvent extends SessionEvent {
  ClientReturnURLSetSessionEvent({int? sessionID, required this.clientReturnURL}) : super(sessionID);

  @JsonKey(name: 'ClientReturnURL')
  final String clientReturnURL;

  factory ClientReturnURLSetSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$ClientReturnURLSetSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$ClientReturnURLSetSessionEventToJson(this);
}

@JsonSerializable()
class SuccessSessionEvent extends SessionEvent {
  SuccessSessionEvent({int? sessionID, required this.result}) : super(sessionID);

  @JsonKey(name: 'Result')
  final String result;

  factory SuccessSessionEvent.fromJson(Map<String, dynamic> json) => _$SuccessSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$SuccessSessionEventToJson(this);
}

@JsonSerializable()
class FailureSessionEvent extends SessionEvent {
  FailureSessionEvent({
    int? sessionID,
    required this.error,
  }) : super(sessionID);

  @JsonKey(name: 'Error')
  final SessionError error;

  factory FailureSessionEvent.fromJson(Map<String, dynamic> json) => _$FailureSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$FailureSessionEventToJson(this);
}

@JsonSerializable()
class CanceledSessionEvent extends SessionEvent {
  CanceledSessionEvent({int? sessionID}) : super(sessionID);

  factory CanceledSessionEvent.fromJson(Map<String, dynamic> json) => _$CanceledSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$CanceledSessionEventToJson(this);
}

@JsonSerializable()
class RequestIssuancePermissionSessionEvent extends SessionEvent {
  RequestIssuancePermissionSessionEvent({
    int? sessionID,
    required this.serverName,
    required this.satisfiable,
    required this.issuedCredentials,
    required this.disclosuresLabels,
    required this.disclosuresCandidates,
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
    int? sessionID,
    required this.serverName,
    required this.satisfiable,
    required this.disclosuresLabels,
    required this.disclosuresCandidates,
    required this.isSignatureSession,
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
  RequestPinSessionEvent({int? sessionID, required this.remainingAttempts}) : super(sessionID);

  @JsonKey(name: 'RemainingAttempts')
  final int remainingAttempts;

  factory RequestPinSessionEvent.fromJson(Map<String, dynamic> json) => _$RequestPinSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$RequestPinSessionEventToJson(this);
}

@JsonSerializable()
class PairingRequiredSessionEvent extends SessionEvent {
  PairingRequiredSessionEvent({int? sessionID, required this.pairingCode}) : super(sessionID);

  @JsonKey(name: 'PairingCode')
  final String pairingCode;

  factory PairingRequiredSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$PairingRequiredSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$PairingRequiredSessionEventToJson(this);
}

@JsonSerializable()
class KeyshareEnrollmentMissingSessionEvent extends SessionEvent {
  KeyshareEnrollmentMissingSessionEvent({int? sessionID, required this.schemeManagerID}) : super(sessionID);

  @JsonKey(name: 'SchemeManagerID')
  final String schemeManagerID;

  factory KeyshareEnrollmentMissingSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$KeyshareEnrollmentMissingSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$KeyshareEnrollmentMissingSessionEventToJson(this);
}

@JsonSerializable()
class KeyshareEnrollmentDeletedSessionEvent extends SessionEvent {
  KeyshareEnrollmentDeletedSessionEvent({int? sessionID, required this.schemeManagerID}) : super(sessionID);

  @JsonKey(name: 'SchemeManagerID')
  final String schemeManagerID;

  factory KeyshareEnrollmentDeletedSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$KeyshareEnrollmentDeletedSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$KeyshareEnrollmentDeletedSessionEventToJson(this);
}

@JsonSerializable()
class KeyshareBlockedSessionEvent extends SessionEvent {
  KeyshareBlockedSessionEvent({
    int? sessionID,
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
  KeyshareEnrollmentIncompleteSessionEvent({int? sessionID, required this.schemeManagerID}) : super(sessionID);

  @JsonKey(name: 'SchemeManagerID')
  final String schemeManagerID;

  factory KeyshareEnrollmentIncompleteSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$KeyshareEnrollmentIncompleteSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$KeyshareEnrollmentIncompleteSessionEventToJson(this);
}

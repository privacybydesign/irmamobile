import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/event.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:json_annotation/json_annotation.dart';

part 'session_events.g.dart';

class SessionEvent extends Event {
  SessionEvent(this.sessionID);

  @JsonKey(name: 'SessionID')
  int sessionID;
}

@JsonSerializable()
class NewSessionEvent extends SessionEvent {
  static int sessionIDCounter = 0;

  NewSessionEvent({this.request, this.continueOnSecondDevice = false}) : super(sessionIDCounter++);

  @JsonKey(name: 'Request')
  SessionPointer request;

  // Whether the session should be continued on the mobile device,
  // or on the device which has displayed a QR code
  bool continueOnSecondDevice;

  factory NewSessionEvent.fromJson(Map<String, dynamic> json) => _$NewSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$NewSessionEventToJson(this);
}

@JsonSerializable()
class RespondPermissionEvent extends SessionEvent {
  RespondPermissionEvent({int sessionID, this.proceed, this.disclosureChoices}) : super(sessionID);

  @JsonKey(name: 'Proceed')
  bool proceed;

  @JsonKey(name: 'DisclosureChoices')
  List<List<AttributeIdentifier>> disclosureChoices;

  factory RespondPermissionEvent.fromJson(Map<String, dynamic> json) => _$RespondPermissionEventFromJson(json);
  Map<String, dynamic> toJson() => _$RespondPermissionEventToJson(this);
}

@JsonSerializable()
class RespondPinEvent extends SessionEvent {
  RespondPinEvent({int sessionID, this.proceed, this.pin}) : super(sessionID);

  @JsonKey(name: 'Proceed')
  bool proceed;

  @JsonKey(name: 'Pin')
  String pin;

  factory RespondPinEvent.fromJson(Map<String, dynamic> json) => _$RespondPinEventFromJson(json);
  Map<String, dynamic> toJson() => _$RespondPinEventToJson(this);
}

@JsonSerializable()
class DismissSessionEvent extends SessionEvent {
  DismissSessionEvent({int sessionID}) : super(sessionID);

  factory DismissSessionEvent.fromJson(Map<String, dynamic> json) => _$DismissSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$DismissSessionEventToJson(this);
}

@JsonSerializable()
class StatusUpdateSessionEvent extends SessionEvent {
  StatusUpdateSessionEvent({int sessionID, this.action, this.status}) : super(sessionID);

  @JsonKey(name: 'Action')
  String action;

  @JsonKey(name: 'Status')
  String status;

  factory StatusUpdateSessionEvent.fromJson(Map<String, dynamic> json) => _$StatusUpdateSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$StatusUpdateSessionEventToJson(this);
}

@JsonSerializable()
class ClientReturnURLSetSessionEvent extends SessionEvent {
  ClientReturnURLSetSessionEvent({int sessionID, this.clientReturnURL}) : super(sessionID);

  @JsonKey(name: 'ClientReturnURL')
  String clientReturnURL;

  factory ClientReturnURLSetSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$ClientReturnURLSetSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$ClientReturnURLSetSessionEventToJson(this);
}

@JsonSerializable()
class SuccessSessionEvent extends SessionEvent {
  SuccessSessionEvent({int sessionID, this.result}) : super(sessionID);

  @JsonKey(name: 'Result')
  String result;

  factory SuccessSessionEvent.fromJson(Map<String, dynamic> json) => _$SuccessSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$SuccessSessionEventToJson(this);
}

@JsonSerializable()
class FailureSessionEvent extends SessionEvent {
  FailureSessionEvent({
    int sessionID,
    this.error,
  }) : super(sessionID);

  @JsonKey(name: 'Error')
  SessionError error;

  factory FailureSessionEvent.fromJson(Map<String, dynamic> json) => _$FailureSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$FailureSessionEventToJson(this);
}

@JsonSerializable()
class CanceledSessionEvent extends SessionEvent {
  CanceledSessionEvent({int sessionID}) : super(sessionID);

  factory CanceledSessionEvent.fromJson(Map<String, dynamic> json) => _$CanceledSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$CanceledSessionEventToJson(this);
}

@JsonSerializable()
class UnsatisfiableRequestSessionEvent extends SessionEvent {
  UnsatisfiableRequestSessionEvent({int sessionID, this.serverName, this.missingDisclosures, this.disclosuresLabels})
      : super(sessionID);

  @JsonKey(name: 'ServerName')
  TranslatedValue serverName;

  @JsonKey(name: 'MissingDisclosures')
  Map<int, Map<int, Map<int, AttributeIdentifier>>> missingDisclosures;

  @JsonKey(name: 'DisclosuresLabels')
  Map<int, TranslatedValue> disclosuresLabels;

  factory UnsatisfiableRequestSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$UnsatisfiableRequestSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$UnsatisfiableRequestSessionEventToJson(this);
}

@JsonSerializable()
class RequestIssuancePermissionSessionEvent extends SessionEvent {
  RequestIssuancePermissionSessionEvent(
      {int sessionID,
      this.serverName,
      this.issuedCredentials,
      this.disclosures,
      this.disclosuresLabels,
      this.disclosuresCandidates})
      : super(sessionID);

  @JsonKey(name: 'ServerName')
  TranslatedValue serverName;

  @JsonKey(name: 'IssuedCredentials')
  List<RawCredential> issuedCredentials;

  @JsonKey(name: 'Disclosures')
  List<List<List<String>>> disclosures;

  @JsonKey(name: 'DisclosuresLabels')
  Map<int, TranslatedValue> disclosuresLabels;

  @JsonKey(name: 'DisclosuresCandidates')
  List<List<List<AttributeIdentifier>>> disclosuresCandidates;

  factory RequestIssuancePermissionSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$RequestIssuancePermissionSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$RequestIssuancePermissionSessionEventToJson(this);
}

@JsonSerializable()
class RequestVerificationPermissionSessionEvent extends SessionEvent {
  RequestVerificationPermissionSessionEvent(
      {int sessionID, this.serverName, this.disclosures, this.disclosuresLabels, this.disclosuresCandidates})
      : super(sessionID);

  @JsonKey(name: 'ServerName')
  TranslatedValue serverName;

  @JsonKey(name: 'Disclosures')
  List<List<List<String>>> disclosures;

  @JsonKey(name: 'DisclosuresLabels')
  Map<int, TranslatedValue> disclosuresLabels;

  @JsonKey(name: 'DisclosuresCandidates')
  List<List<List<AttributeIdentifier>>> disclosuresCandidates;

  @JsonKey(name: 'IsSignatureSession')
  bool isSignatureSession;

  @JsonKey(name: 'SignedMessage')
  String signedMessage;

  factory RequestVerificationPermissionSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$RequestVerificationPermissionSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$RequestVerificationPermissionSessionEventToJson(this);
}

@JsonSerializable()
class RequestPinSessionEvent extends SessionEvent {
  RequestPinSessionEvent({int sessionID, this.remainingAttempts}) : super(sessionID);

  @JsonKey(name: 'RemainingAttempts')
  int remainingAttempts;

  factory RequestPinSessionEvent.fromJson(Map<String, dynamic> json) => _$RequestPinSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$RequestPinSessionEventToJson(this);
}

@JsonSerializable()
class KeyshareEnrollmentMissingSessionEvent extends SessionEvent {
  KeyshareEnrollmentMissingSessionEvent({int sessionID, this.schemeManagerID}) : super(sessionID);

  @JsonKey(name: 'SchemeManagerID')
  String schemeManagerID;

  factory KeyshareEnrollmentMissingSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$KeyshareEnrollmentMissingSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$KeyshareEnrollmentMissingSessionEventToJson(this);
}

@JsonSerializable()
class KeyshareEnrollmentDeletedSessionEvent extends SessionEvent {
  KeyshareEnrollmentDeletedSessionEvent({int sessionID, this.schemeManagerID}) : super(sessionID);

  @JsonKey(name: 'SchemeManagerID')
  String schemeManagerID;

  factory KeyshareEnrollmentDeletedSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$KeyshareEnrollmentDeletedSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$KeyshareEnrollmentDeletedSessionEventToJson(this);
}

@JsonSerializable()
class KeyshareBlockedSessionEvent extends SessionEvent {
  KeyshareBlockedSessionEvent({int sessionID, this.schemeManagerID, this.duration}) : super(sessionID);

  @JsonKey(name: 'SchemeManagerID')
  String schemeManagerID;

  @JsonKey(name: 'Duration')
  int duration;

  factory KeyshareBlockedSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$KeyshareBlockedSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$KeyshareBlockedSessionEventToJson(this);
}

@JsonSerializable()
class KeyshareEnrollmentIncompleteSessionEvent extends SessionEvent {
  KeyshareEnrollmentIncompleteSessionEvent({int sessionID, this.schemeManagerID}) : super(sessionID);

  @JsonKey(name: 'SchemeManagerID')
  String schemeManagerID;

  factory KeyshareEnrollmentIncompleteSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$KeyshareEnrollmentIncompleteSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$KeyshareEnrollmentIncompleteSessionEventToJson(this);
}

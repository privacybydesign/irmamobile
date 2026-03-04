import "package:flutter/cupertino.dart";
import "package:json_annotation/json_annotation.dart";

import "attribute.dart";
import "credentials.dart";
import "event.dart";
import "session.dart";
import "translated_value.dart";

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

  factory RespondAuthorizationCodeEvent.fromJson(
    Map<String, dynamic> json,
  ) => _$RespondAuthorizationCodeEventFromJson(json);
  Map<String, dynamic> toJson() =>
      _$RespondAuthorizationCodeEventToJson(this);
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

  factory RespondTokenEvent.fromJson(
    Map<String, dynamic> json,
  ) => _$RespondTokenEventFromJson(json);
  Map<String, dynamic> toJson() =>
      _$RespondTokenEventToJson(this);
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

@JsonSerializable(fieldRename: FieldRename.snake)
class StatusUpdateSessionEvent extends SessionEvent {
  StatusUpdateSessionEvent({
    required int sessionID,
    required this.action,
    required this.status,
  }) : super(sessionID);

  final String action;

  final String status;

  factory StatusUpdateSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$StatusUpdateSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$StatusUpdateSessionEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ClientReturnURLSetSessionEvent extends SessionEvent {
  ClientReturnURLSetSessionEvent({
    required int sessionID,
    required this.clientReturnURL,
  }) : super(sessionID);

  @JsonKey(name: "client_return_url")
  final String clientReturnURL;

  factory ClientReturnURLSetSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$ClientReturnURLSetSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$ClientReturnURLSetSessionEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SuccessSessionEvent extends SessionEvent {
  SuccessSessionEvent({required int sessionID}) : super(sessionID);

  factory SuccessSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$SuccessSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$SuccessSessionEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class FailureSessionEvent extends SessionEvent {
  FailureSessionEvent({required int sessionID, required this.error})
    : super(sessionID);

  final SessionError error;

  factory FailureSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$FailureSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$FailureSessionEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CanceledSessionEvent extends SessionEvent {
  CanceledSessionEvent({required int sessionID}) : super(sessionID);

  factory CanceledSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$CanceledSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$CanceledSessionEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RequestIssuancePermissionSessionEvent extends SessionEvent {
  RequestIssuancePermissionSessionEvent({
    required int sessionID,
    required this.serverName,
    required this.satisfiable,
    required this.issuedCredentials,
    this.disclosuresLabels,
    this.disclosuresCandidates = const [],
  }) : super(sessionID);

  final RequestorInfo serverName;

  final bool satisfiable;

  final List<RawMultiFormatCredential> issuedCredentials;

  final Map<int, TranslatedValue>? disclosuresLabels;

  final List<List<List<DisclosureCandidate>>> disclosuresCandidates;

  factory RequestIssuancePermissionSessionEvent.fromJson(
    Map<String, dynamic> json,
  ) => _$RequestIssuancePermissionSessionEventFromJson(json);
  Map<String, dynamic> toJson() =>
      _$RequestIssuancePermissionSessionEventToJson(this);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class RequestAuthorizationCodeFlowSessionEvent
    extends SessionEvent {
  RequestAuthorizationCodeFlowSessionEvent({
    required int sessionID,
    required this.requestorInfo,
    required this.authorizationRequestUrl,
    this.credentialInfoList,
  }) : super(sessionID);

  final RequestorInfo requestorInfo;

  final List<CredentialTypeInfo>? credentialInfoList;

  final String authorizationRequestUrl;

  factory RequestAuthorizationCodeFlowSessionEvent.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$RequestAuthorizationCodeFlowSessionEventFromJson(
        json,
      );
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class AuthorizationRequestParameters {
  AuthorizationRequestParameters({
    required this.authorizationRequestUrl,
  });

  final String authorizationRequestUrl;

  factory AuthorizationRequestParameters.fromJson(Map<String, dynamic> json) =>
      _$AuthorizationRequestParametersFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class RequestPreAuthorizedCodeFlowPermissionSessionEvent extends SessionEvent {
  RequestPreAuthorizedCodeFlowPermissionSessionEvent({
    required int sessionID,
    required this.requestorInfo,
    this.credentialInfoList,
    this.transactionCodeParameters,
  }) : super(sessionID);

  final RequestorInfo requestorInfo;

  final List<CredentialTypeInfo>? credentialInfoList;

  @JsonKey(required: false)
  final PreAuthorizedCodeTransactionCodeParameters? transactionCodeParameters;

  factory RequestPreAuthorizedCodeFlowPermissionSessionEvent.fromJson(
    Map<String, dynamic> json,
  ) => _$RequestPreAuthorizedCodeFlowPermissionSessionEventFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class PreAuthorizedCodeTransactionCodeParameters {
  PreAuthorizedCodeTransactionCodeParameters({
    required this.inputMode,
    this.length,
    this.description,
  });

  final String inputMode;

  @JsonKey(required: false)
  final int? length;

  @JsonKey(required: false)
  final String? description;

  factory PreAuthorizedCodeTransactionCodeParameters.fromJson(
    Map<String, dynamic> json,
  ) => _$PreAuthorizedCodeTransactionCodeParametersFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake)
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

  final RequestorInfo serverName;

  final bool satisfiable;

  final Map<int, TranslatedValue>? disclosuresLabels;

  final List<List<List<DisclosureCandidate>>> disclosuresCandidates;

  final bool isSignatureSession;

  final String? signedMessage;

  factory RequestVerificationPermissionSessionEvent.fromJson(
    Map<String, dynamic> json,
  ) => _$RequestVerificationPermissionSessionEventFromJson(json);
  Map<String, dynamic> toJson() =>
      _$RequestVerificationPermissionSessionEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RequestPinSessionEvent extends SessionEvent {
  RequestPinSessionEvent({
    required int sessionID,
    required this.remainingAttempts,
  }) : super(sessionID);

  final int remainingAttempts;

  factory RequestPinSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$RequestPinSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$RequestPinSessionEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class PairingRequiredSessionEvent extends SessionEvent {
  PairingRequiredSessionEvent({
    required int sessionID,
    required this.pairingCode,
  }) : super(sessionID);

  final String pairingCode;

  factory PairingRequiredSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$PairingRequiredSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$PairingRequiredSessionEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class KeyshareEnrollmentMissingSessionEvent extends SessionEvent {
  KeyshareEnrollmentMissingSessionEvent({
    required int sessionID,
    required this.schemeManagerID,
  }) : super(sessionID);

  @JsonKey(name: "scheme_manager_id")
  final String schemeManagerID;

  factory KeyshareEnrollmentMissingSessionEvent.fromJson(
    Map<String, dynamic> json,
  ) => _$KeyshareEnrollmentMissingSessionEventFromJson(json);
  Map<String, dynamic> toJson() =>
      _$KeyshareEnrollmentMissingSessionEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class KeyshareEnrollmentDeletedSessionEvent extends SessionEvent {
  KeyshareEnrollmentDeletedSessionEvent({
    required int sessionID,
    required this.schemeManagerID,
  }) : super(sessionID);

  @JsonKey(name: "scheme_manager_id")
  final String schemeManagerID;

  factory KeyshareEnrollmentDeletedSessionEvent.fromJson(
    Map<String, dynamic> json,
  ) => _$KeyshareEnrollmentDeletedSessionEventFromJson(json);
  Map<String, dynamic> toJson() =>
      _$KeyshareEnrollmentDeletedSessionEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class KeyshareBlockedSessionEvent extends SessionEvent {
  KeyshareBlockedSessionEvent({
    required int sessionID,
    required this.schemeManagerID,
    required this.duration,
  }) : super(sessionID);

  @JsonKey(name: "scheme_manager_id")
  final String schemeManagerID;

  final int duration;

  factory KeyshareBlockedSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$KeyshareBlockedSessionEventFromJson(json);
  Map<String, dynamic> toJson() => _$KeyshareBlockedSessionEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class KeyshareEnrollmentIncompleteSessionEvent extends SessionEvent {
  KeyshareEnrollmentIncompleteSessionEvent({
    required int sessionID,
    required this.schemeManagerID,
  }) : super(sessionID);

  @JsonKey(name: "scheme_manager_id")
  final String schemeManagerID;

  factory KeyshareEnrollmentIncompleteSessionEvent.fromJson(
    Map<String, dynamic> json,
  ) => _$KeyshareEnrollmentIncompleteSessionEventFromJson(json);
  Map<String, dynamic> toJson() =>
      _$KeyshareEnrollmentIncompleteSessionEventToJson(this);
}

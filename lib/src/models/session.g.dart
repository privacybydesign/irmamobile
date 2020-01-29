// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NewSessionEvent _$NewSessionEventFromJson(Map<String, dynamic> json) {
  return NewSessionEvent(
    request: json['Request'] == null ? null : SessionPointer.fromJson(json['Request'] as Map<String, dynamic>),
  )..sessionID = json['SessionID'] as int;
}

Map<String, dynamic> _$NewSessionEventToJson(NewSessionEvent instance) => <String, dynamic>{
      'SessionID': instance.sessionID,
      'Request': instance.request,
    };

SessionPointer _$SessionPointerFromJson(Map<String, dynamic> json) {
  return SessionPointer(
    u: json['u'] as String,
    irmaqr: json['irmaqr'] as String,
  );
}

Map<String, dynamic> _$SessionPointerToJson(SessionPointer instance) => <String, dynamic>{
      'u': instance.u,
      'irmaqr': instance.irmaqr,
    };

RespondPermissionEvent _$RespondPermissionEventFromJson(Map<String, dynamic> json) {
  return RespondPermissionEvent(
    sessionID: json['SessionID'] as int,
    proceed: json['Proceed'] as bool,
    disclosureChoices: (json['DisclosureChoices'] as List)
        ?.map((e) => (e as List)
            ?.map((e) => e == null ? null : AttributeIdentifier.fromJson(e as Map<String, dynamic>))
            ?.toList())
        ?.toList(),
  );
}

Map<String, dynamic> _$RespondPermissionEventToJson(RespondPermissionEvent instance) => <String, dynamic>{
      'SessionID': instance.sessionID,
      'Proceed': instance.proceed,
      'DisclosureChoices': instance.disclosureChoices,
    };

RespondPinEvent _$RespondPinEventFromJson(Map<String, dynamic> json) {
  return RespondPinEvent(
    sessionID: json['SessionID'] as int,
    proceed: json['Proceed'] as bool,
    pin: json['Pin'] as String,
  );
}

Map<String, dynamic> _$RespondPinEventToJson(RespondPinEvent instance) => <String, dynamic>{
      'SessionID': instance.sessionID,
      'Proceed': instance.proceed,
      'Pin': instance.pin,
    };

DismissSessionEvent _$DismissSessionEventFromJson(Map<String, dynamic> json) {
  return DismissSessionEvent(
    sessionID: json['SessionID'] as int,
  );
}

Map<String, dynamic> _$DismissSessionEventToJson(DismissSessionEvent instance) => <String, dynamic>{
      'SessionID': instance.sessionID,
    };

DeleteCredentialEvent _$DeleteCredentialEventFromJson(Map<String, dynamic> json) {
  return DeleteCredentialEvent(
    hash: json['Hash'] as String,
  );
}

Map<String, dynamic> _$DeleteCredentialEventToJson(DeleteCredentialEvent instance) => <String, dynamic>{
      'Hash': instance.hash,
    };

SetCrashReportingPreferenceEvent _$SetCrashReportingPreferenceEventFromJson(Map<String, dynamic> json) {
  return SetCrashReportingPreferenceEvent(
    enableCrashReporting: json['EnableCrashReporting'] as bool,
  );
}

Map<String, dynamic> _$SetCrashReportingPreferenceEventToJson(SetCrashReportingPreferenceEvent instance) =>
    <String, dynamic>{
      'EnableCrashReporting': instance.enableCrashReporting,
    };

EnrollmentStatusEvent _$EnrollmentStatusEventFromJson(Map<String, dynamic> json) {
  return EnrollmentStatusEvent(
    enrolledSchemeManagerIds: (json['EnrolledSchemeManagerIds'] as List)?.map((e) => e as String)?.toList(),
    unenrolledSchemeManagerIds: (json['UnenrolledSchemeManagerIds'] as List)?.map((e) => e as String)?.toList(),
  );
}

Map<String, dynamic> _$EnrollmentStatusEventToJson(EnrollmentStatusEvent instance) => <String, dynamic>{
      'EnrolledSchemeManagerIds': instance.enrolledSchemeManagerIds,
      'UnenrolledSchemeManagerIds': instance.unenrolledSchemeManagerIds,
    };

StatusUpdateSessionEvent _$StatusUpdateSessionEventFromJson(Map<String, dynamic> json) {
  return StatusUpdateSessionEvent(
    sessionID: json['SessionID'] as int,
    action: json['Action'] as String,
    status: json['Status'] as String,
  );
}

Map<String, dynamic> _$StatusUpdateSessionEventToJson(StatusUpdateSessionEvent instance) => <String, dynamic>{
      'SessionID': instance.sessionID,
      'Action': instance.action,
      'Status': instance.status,
    };

ClientReturnURLSetSessionEvent _$ClientReturnURLSetSessionEventFromJson(Map<String, dynamic> json) {
  return ClientReturnURLSetSessionEvent(
    sessionID: json['SessionID'] as int,
    clientReturnURL: json['ClientReturnURL'] as String,
  );
}

Map<String, dynamic> _$ClientReturnURLSetSessionEventToJson(ClientReturnURLSetSessionEvent instance) =>
    <String, dynamic>{
      'SessionID': instance.sessionID,
      'ClientReturnURL': instance.clientReturnURL,
    };

SuccessSessionEvent _$SuccessSessionEventFromJson(Map<String, dynamic> json) {
  return SuccessSessionEvent(
    sessionID: json['SessionID'] as int,
    result: json['Result'] as String,
  );
}

Map<String, dynamic> _$SuccessSessionEventToJson(SuccessSessionEvent instance) => <String, dynamic>{
      'SessionID': instance.sessionID,
      'Result': instance.result,
    };

FailureSessionEvent _$FailureSessionEventFromJson(Map<String, dynamic> json) {
  return FailureSessionEvent(
    sessionID: json['SessionID'] as int,
    error: json['Error'] == null ? null : SessionError.fromJson(json['Error'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$FailureSessionEventToJson(FailureSessionEvent instance) => <String, dynamic>{
      'SessionID': instance.sessionID,
      'Error': instance.error,
    };

SessionError _$SessionErrorFromJson(Map<String, dynamic> json) {
  return SessionError(
    errorType: json['ErrorType'] as String,
    wrappedError: json['WrappedError'] as String,
    info: json['Info'] as String,
    stack: json['Stack'] as String,
    remoteStatus: json['RemoteStatus'] as String,
    remoteError: json['RemoteError'] as String,
  );
}

Map<String, dynamic> _$SessionErrorToJson(SessionError instance) => <String, dynamic>{
      'ErrorType': instance.errorType,
      'WrappedError': instance.wrappedError,
      'Info': instance.info,
      'Stack': instance.stack,
      'RemoteStatus': instance.remoteStatus,
      'RemoteError': instance.remoteError,
    };

CanceledSessionEvent _$CanceledSessionEventFromJson(Map<String, dynamic> json) {
  return CanceledSessionEvent(
    sessionID: json['SessionID'] as int,
  );
}

Map<String, dynamic> _$CanceledSessionEventToJson(CanceledSessionEvent instance) => <String, dynamic>{
      'SessionID': instance.sessionID,
    };

UnsatisfiableRequestSessionEvent _$UnsatisfiableRequestSessionEventFromJson(Map<String, dynamic> json) {
  return UnsatisfiableRequestSessionEvent(
    sessionID: json['SessionID'] as int,
    serverName:
        json['ServerName'] == null ? null : TranslatedValue.fromJson(json['ServerName'] as Map<String, dynamic>),
    missingDisclosures: (json['MissingDisclosures'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          int.parse(k),
          (e as Map<String, dynamic>)?.map(
            (k, e) => MapEntry(
                int.parse(k),
                (e as Map<String, dynamic>)?.map(
                  (k, e) => MapEntry(
                      int.parse(k), e == null ? null : AttributeIdentifier.fromJson(e as Map<String, dynamic>)),
                )),
          )),
    ),
    disclosuresLabels: (json['DisclosuresLabels'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(int.parse(k), e == null ? null : TranslatedValue.fromJson(e as Map<String, dynamic>)),
    ),
  );
}

Map<String, dynamic> _$UnsatisfiableRequestSessionEventToJson(UnsatisfiableRequestSessionEvent instance) =>
    <String, dynamic>{
      'SessionID': instance.sessionID,
      'ServerName': instance.serverName,
      'MissingDisclosures': instance.missingDisclosures?.map((k, e) => MapEntry(
          k.toString(), e?.map((k, e) => MapEntry(k.toString(), e?.map((k, e) => MapEntry(k.toString(), e)))))),
      'DisclosuresLabels': instance.disclosuresLabels?.map((k, e) => MapEntry(k.toString(), e)),
    };

RequestIssuancePermissionSessionEvent _$RequestIssuancePermissionSessionEventFromJson(Map<String, dynamic> json) {
  return RequestIssuancePermissionSessionEvent(
    sessionID: json['SessionID'] as int,
    serverName:
        json['ServerName'] == null ? null : TranslatedValue.fromJson(json['ServerName'] as Map<String, dynamic>),
    issuedCredentials: (json['IssuedCredentials'] as List)
        ?.map((e) => e == null ? null : RawCredential.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    disclosures: (json['Disclosures'] as List)
        ?.map((e) => (e as List)?.map((e) => (e as List)?.map((e) => e as String)?.toList())?.toList())
        ?.toList(),
    disclosuresLabels: (json['DisclosuresLabels'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(int.parse(k), e == null ? null : TranslatedValue.fromJson(e as Map<String, dynamic>)),
    ),
    disclosuresCandidates: (json['DisclosuresCandidates'] as List)
        ?.map((e) => (e as List)
            ?.map((e) => (e as List)
                ?.map((e) => e == null ? null : AttributeIdentifier.fromJson(e as Map<String, dynamic>))
                ?.toList())
            ?.toList())
        ?.toList(),
  );
}

Map<String, dynamic> _$RequestIssuancePermissionSessionEventToJson(RequestIssuancePermissionSessionEvent instance) =>
    <String, dynamic>{
      'SessionID': instance.sessionID,
      'ServerName': instance.serverName,
      'IssuedCredentials': instance.issuedCredentials,
      'Disclosures': instance.disclosures,
      'DisclosuresLabels': instance.disclosuresLabels?.map((k, e) => MapEntry(k.toString(), e)),
      'DisclosuresCandidates': instance.disclosuresCandidates,
    };

RequestVerificationPermissionSessionEvent _$RequestVerificationPermissionSessionEventFromJson(
    Map<String, dynamic> json) {
  return RequestVerificationPermissionSessionEvent(
    sessionID: json['SessionID'] as int,
    serverName:
        json['ServerName'] == null ? null : TranslatedValue.fromJson(json['ServerName'] as Map<String, dynamic>),
    disclosures: (json['Disclosures'] as List)
        ?.map((e) => (e as List)?.map((e) => (e as List)?.map((e) => e as String)?.toList())?.toList())
        ?.toList(),
    disclosuresLabels: (json['DisclosuresLabels'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(int.parse(k), e == null ? null : TranslatedValue.fromJson(e as Map<String, dynamic>)),
    ),
    disclosuresCandidates: (json['DisclosuresCandidates'] as List)
        ?.map((e) => (e as List)
            ?.map((e) => (e as List)
                ?.map((e) => e == null ? null : AttributeIdentifier.fromJson(e as Map<String, dynamic>))
                ?.toList())
            ?.toList())
        ?.toList(),
  );
}

Map<String, dynamic> _$RequestVerificationPermissionSessionEventToJson(
        RequestVerificationPermissionSessionEvent instance) =>
    <String, dynamic>{
      'SessionID': instance.sessionID,
      'ServerName': instance.serverName,
      'Disclosures': instance.disclosures,
      'DisclosuresLabels': instance.disclosuresLabels?.map((k, e) => MapEntry(k.toString(), e)),
      'DisclosuresCandidates': instance.disclosuresCandidates,
    };

RequestSignaturePermissionSessionEvent _$RequestSignaturePermissionSessionEventFromJson(Map<String, dynamic> json) {
  return RequestSignaturePermissionSessionEvent(
    sessionID: json['SessionID'] as int,
    serverName:
        json['ServerName'] == null ? null : TranslatedValue.fromJson(json['ServerName'] as Map<String, dynamic>),
    disclosures: (json['Disclosures'] as List)
        ?.map((e) => (e as List)?.map((e) => (e as List)?.map((e) => e as String)?.toList())?.toList())
        ?.toList(),
    disclosuresLabels: (json['DisclosuresLabels'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(int.parse(k), e == null ? null : TranslatedValue.fromJson(e as Map<String, dynamic>)),
    ),
    disclosuresCandidates: (json['DisclosuresCandidates'] as List)
        ?.map((e) => (e as List)
            ?.map((e) => (e as List)
                ?.map((e) => e == null ? null : AttributeIdentifier.fromJson(e as Map<String, dynamic>))
                ?.toList())
            ?.toList())
        ?.toList(),
    message: json['Message'] as String,
  );
}

Map<String, dynamic> _$RequestSignaturePermissionSessionEventToJson(RequestSignaturePermissionSessionEvent instance) =>
    <String, dynamic>{
      'SessionID': instance.sessionID,
      'ServerName': instance.serverName,
      'Disclosures': instance.disclosures,
      'DisclosuresLabels': instance.disclosuresLabels?.map((k, e) => MapEntry(k.toString(), e)),
      'DisclosuresCandidates': instance.disclosuresCandidates,
      'Message': instance.message,
    };

RequestPinSessionEvent _$RequestPinSessionEventFromJson(Map<String, dynamic> json) {
  return RequestPinSessionEvent(
    sessionID: json['SessionID'] as int,
    remainingAttempts: json['RemainingAttempts'] as int,
  );
}

Map<String, dynamic> _$RequestPinSessionEventToJson(RequestPinSessionEvent instance) => <String, dynamic>{
      'SessionID': instance.sessionID,
      'RemainingAttempts': instance.remainingAttempts,
    };

KeyshareEnrollmentMissingSessionEvent _$KeyshareEnrollmentMissingSessionEventFromJson(Map<String, dynamic> json) {
  return KeyshareEnrollmentMissingSessionEvent(
    sessionID: json['SessionID'] as int,
    schemeManagerID: json['SchemeManagerID'] as String,
  );
}

Map<String, dynamic> _$KeyshareEnrollmentMissingSessionEventToJson(KeyshareEnrollmentMissingSessionEvent instance) =>
    <String, dynamic>{
      'SessionID': instance.sessionID,
      'SchemeManagerID': instance.schemeManagerID,
    };

KeyshareEnrollmentDeletedSessionEvent _$KeyshareEnrollmentDeletedSessionEventFromJson(Map<String, dynamic> json) {
  return KeyshareEnrollmentDeletedSessionEvent(
    sessionID: json['SessionID'] as int,
    schemeManagerID: json['SchemeManagerID'] as String,
  );
}

Map<String, dynamic> _$KeyshareEnrollmentDeletedSessionEventToJson(KeyshareEnrollmentDeletedSessionEvent instance) =>
    <String, dynamic>{
      'SessionID': instance.sessionID,
      'SchemeManagerID': instance.schemeManagerID,
    };

KeyshareBlockedSessionEvent _$KeyshareBlockedSessionEventFromJson(Map<String, dynamic> json) {
  return KeyshareBlockedSessionEvent(
    sessionID: json['SessionID'] as int,
    schemeManagerID: json['SchemeManagerID'] as String,
    duration: json['Duration'] as int,
  );
}

Map<String, dynamic> _$KeyshareBlockedSessionEventToJson(KeyshareBlockedSessionEvent instance) => <String, dynamic>{
      'SessionID': instance.sessionID,
      'SchemeManagerID': instance.schemeManagerID,
      'Duration': instance.duration,
    };

KeyshareEnrollmentIncompleteSessionEvent _$KeyshareEnrollmentIncompleteSessionEventFromJson(Map<String, dynamic> json) {
  return KeyshareEnrollmentIncompleteSessionEvent(
    sessionID: json['SessionID'] as int,
    schemeManagerID: json['SchemeManagerID'] as String,
  );
}

Map<String, dynamic> _$KeyshareEnrollmentIncompleteSessionEventToJson(
        KeyshareEnrollmentIncompleteSessionEvent instance) =>
    <String, dynamic>{
      'SessionID': instance.sessionID,
      'SchemeManagerID': instance.schemeManagerID,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$NewSessionEventToJson(NewSessionEvent instance) =>
    <String, dynamic>{
      'session_id': instance.sessionID,
      'request': instance.request,
      'previously_launched_credentials': instance.previouslyLaunchedCredentials
          .toList(),
    };

RespondPreAuthorizedCodeFlowPermissionEvent
_$RespondPreAuthorizedCodeFlowPermissionEventFromJson(
  Map<String, dynamic> json,
) => RespondPreAuthorizedCodeFlowPermissionEvent(
  sessionID: (json['session_id'] as num).toInt(),
  proceed: json['proceed'] as bool,
  transactionCode: json['transaction_code'] as String?,
);

Map<String, dynamic> _$RespondPreAuthorizedCodeFlowPermissionEventToJson(
  RespondPreAuthorizedCodeFlowPermissionEvent instance,
) => <String, dynamic>{
  'session_id': instance.sessionID,
  'proceed': instance.proceed,
  'transaction_code': instance.transactionCode,
};

RespondAuthorizationCodeEvent _$RespondAuthorizationCodeEventFromJson(
  Map<String, dynamic> json,
) => RespondAuthorizationCodeEvent(
  sessionID: (json['session_id'] as num).toInt(),
  proceed: json['proceed'] as bool,
  code: json['code'] as String,
);

Map<String, dynamic> _$RespondAuthorizationCodeEventToJson(
  RespondAuthorizationCodeEvent instance,
) => <String, dynamic>{
  'session_id': instance.sessionID,
  'proceed': instance.proceed,
  'code': instance.code,
};

RespondTokenEvent _$RespondTokenEventFromJson(Map<String, dynamic> json) =>
    RespondTokenEvent(
      sessionID: (json['session_id'] as num).toInt(),
      proceed: json['proceed'] as bool,
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
    );

Map<String, dynamic> _$RespondTokenEventToJson(RespondTokenEvent instance) =>
    <String, dynamic>{
      'session_id': instance.sessionID,
      'proceed': instance.proceed,
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
    };

RespondPermissionEvent _$RespondPermissionEventFromJson(
  Map<String, dynamic> json,
) => RespondPermissionEvent(
  sessionID: (json['session_id'] as num).toInt(),
  proceed: json['proceed'] as bool,
  disclosureChoices: (json['disclosure_choices'] as List<dynamic>)
      .map(
        (e) => (e as List<dynamic>)
            .map((e) => AttributeIdentifier.fromJson(e as Map<String, dynamic>))
            .toList(),
      )
      .toList(),
);

Map<String, dynamic> _$RespondPermissionEventToJson(
  RespondPermissionEvent instance,
) => <String, dynamic>{
  'session_id': instance.sessionID,
  'proceed': instance.proceed,
  'disclosure_choices': instance.disclosureChoices,
};

RespondPinEvent _$RespondPinEventFromJson(Map<String, dynamic> json) =>
    RespondPinEvent(
      sessionID: (json['session_id'] as num).toInt(),
      proceed: json['proceed'] as bool,
      pin: json['pin'] as String?,
    );

Map<String, dynamic> _$RespondPinEventToJson(RespondPinEvent instance) =>
    <String, dynamic>{
      'session_id': instance.sessionID,
      'proceed': instance.proceed,
      'pin': instance.pin,
    };

DismissSessionEvent _$DismissSessionEventFromJson(Map<String, dynamic> json) =>
    DismissSessionEvent(sessionID: (json['session_id'] as num).toInt());

Map<String, dynamic> _$DismissSessionEventToJson(
  DismissSessionEvent instance,
) => <String, dynamic>{'session_id': instance.sessionID};

StatusUpdateSessionEvent _$StatusUpdateSessionEventFromJson(
  Map<String, dynamic> json,
) => StatusUpdateSessionEvent(
  sessionID: (json['session_id'] as num).toInt(),
  action: json['action'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$StatusUpdateSessionEventToJson(
  StatusUpdateSessionEvent instance,
) => <String, dynamic>{
  'session_id': instance.sessionID,
  'action': instance.action,
  'status': instance.status,
};

ClientReturnURLSetSessionEvent _$ClientReturnURLSetSessionEventFromJson(
  Map<String, dynamic> json,
) => ClientReturnURLSetSessionEvent(
  sessionID: (json['session_id'] as num).toInt(),
  clientReturnURL: json['client_return_url'] as String,
);

Map<String, dynamic> _$ClientReturnURLSetSessionEventToJson(
  ClientReturnURLSetSessionEvent instance,
) => <String, dynamic>{
  'session_id': instance.sessionID,
  'client_return_url': instance.clientReturnURL,
};

SuccessSessionEvent _$SuccessSessionEventFromJson(Map<String, dynamic> json) =>
    SuccessSessionEvent(sessionID: (json['session_id'] as num).toInt());

Map<String, dynamic> _$SuccessSessionEventToJson(
  SuccessSessionEvent instance,
) => <String, dynamic>{'session_id': instance.sessionID};

FailureSessionEvent _$FailureSessionEventFromJson(Map<String, dynamic> json) =>
    FailureSessionEvent(
      sessionID: (json['session_id'] as num).toInt(),
      error: SessionError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FailureSessionEventToJson(
  FailureSessionEvent instance,
) => <String, dynamic>{
  'session_id': instance.sessionID,
  'error': instance.error,
};

CanceledSessionEvent _$CanceledSessionEventFromJson(
  Map<String, dynamic> json,
) => CanceledSessionEvent(sessionID: (json['session_id'] as num).toInt());

Map<String, dynamic> _$CanceledSessionEventToJson(
  CanceledSessionEvent instance,
) => <String, dynamic>{'session_id': instance.sessionID};

RequestIssuancePermissionSessionEvent
_$RequestIssuancePermissionSessionEventFromJson(
  Map<String, dynamic> json,
) => RequestIssuancePermissionSessionEvent(
  sessionID: (json['session_id'] as num).toInt(),
  serverName: RequestorInfo.fromJson(
    json['server_name'] as Map<String, dynamic>,
  ),
  satisfiable: json['satisfiable'] as bool,
  issuedCredentials: (json['issued_credentials'] as List<dynamic>)
      .map((e) => RawMultiFormatCredential.fromJson(e as Map<String, dynamic>))
      .toList(),
  disclosuresLabels: (json['disclosures_labels'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(
      int.parse(k),
      TranslatedValue.fromJson(e as Map<String, dynamic>?),
    ),
  ),
  disclosuresCandidates:
      (json['disclosures_candidates'] as List<dynamic>?)
          ?.map(
            (e) => (e as List<dynamic>)
                .map(
                  (e) => (e as List<dynamic>)
                      .map(
                        (e) => DisclosureCandidate.fromJson(
                          e as Map<String, dynamic>,
                        ),
                      )
                      .toList(),
                )
                .toList(),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$RequestIssuancePermissionSessionEventToJson(
  RequestIssuancePermissionSessionEvent instance,
) => <String, dynamic>{
  'session_id': instance.sessionID,
  'server_name': instance.serverName,
  'satisfiable': instance.satisfiable,
  'issued_credentials': instance.issuedCredentials,
  'disclosures_labels': instance.disclosuresLabels?.map(
    (k, e) => MapEntry(k.toString(), e),
  ),
  'disclosures_candidates': instance.disclosuresCandidates,
};

RequestAuthorizationCodeFlowSessionEvent
_$RequestAuthorizationCodeFlowSessionEventFromJson(Map<String, dynamic> json) =>
    RequestAuthorizationCodeFlowSessionEvent(
      sessionID: (json['session_id'] as num).toInt(),
      requestorInfo: RequestorInfo.fromJson(
        json['requestor_info'] as Map<String, dynamic>,
      ),
      authorizationRequestUrl: json['authorization_request_url'] as String,
      credentialInfoList: (json['credential_info_list'] as List<dynamic>?)
          ?.map((e) => CredentialTypeInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

AuthorizationRequestParameters _$AuthorizationRequestParametersFromJson(
  Map<String, dynamic> json,
) => AuthorizationRequestParameters(
  authorizationRequestUrl: json['authorization_request_url'] as String,
);

RequestPreAuthorizedCodeFlowPermissionSessionEvent
_$RequestPreAuthorizedCodeFlowPermissionSessionEventFromJson(
  Map<String, dynamic> json,
) => RequestPreAuthorizedCodeFlowPermissionSessionEvent(
  sessionID: (json['session_id'] as num).toInt(),
  requestorInfo: RequestorInfo.fromJson(
    json['requestor_info'] as Map<String, dynamic>,
  ),
  credentialInfoList: (json['credential_info_list'] as List<dynamic>?)
      ?.map((e) => CredentialTypeInfo.fromJson(e as Map<String, dynamic>))
      .toList(),
  transactionCodeParameters: json['transaction_code_parameters'] == null
      ? null
      : PreAuthorizedCodeTransactionCodeParameters.fromJson(
          json['transaction_code_parameters'] as Map<String, dynamic>,
        ),
);

PreAuthorizedCodeTransactionCodeParameters
_$PreAuthorizedCodeTransactionCodeParametersFromJson(
  Map<String, dynamic> json,
) => PreAuthorizedCodeTransactionCodeParameters(
  inputMode: json['input_mode'] as String,
  length: (json['length'] as num?)?.toInt(),
  description: json['description'] as String?,
);

RequestVerificationPermissionSessionEvent
_$RequestVerificationPermissionSessionEventFromJson(
  Map<String, dynamic> json,
) => RequestVerificationPermissionSessionEvent(
  sessionID: (json['session_id'] as num).toInt(),
  serverName: RequestorInfo.fromJson(
    json['server_name'] as Map<String, dynamic>,
  ),
  satisfiable: json['satisfiable'] as bool,
  disclosuresCandidates: (json['disclosures_candidates'] as List<dynamic>)
      .map(
        (e) => (e as List<dynamic>)
            .map(
              (e) => (e as List<dynamic>)
                  .map(
                    (e) =>
                        DisclosureCandidate.fromJson(e as Map<String, dynamic>),
                  )
                  .toList(),
            )
            .toList(),
      )
      .toList(),
  isSignatureSession: json['is_signature_session'] as bool,
  disclosuresLabels: (json['disclosures_labels'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(
      int.parse(k),
      TranslatedValue.fromJson(e as Map<String, dynamic>?),
    ),
  ),
  signedMessage: json['signed_message'] as String?,
);

Map<String, dynamic> _$RequestVerificationPermissionSessionEventToJson(
  RequestVerificationPermissionSessionEvent instance,
) => <String, dynamic>{
  'session_id': instance.sessionID,
  'server_name': instance.serverName,
  'satisfiable': instance.satisfiable,
  'disclosures_labels': instance.disclosuresLabels?.map(
    (k, e) => MapEntry(k.toString(), e),
  ),
  'disclosures_candidates': instance.disclosuresCandidates,
  'is_signature_session': instance.isSignatureSession,
  'signed_message': instance.signedMessage,
};

RequestPinSessionEvent _$RequestPinSessionEventFromJson(
  Map<String, dynamic> json,
) => RequestPinSessionEvent(
  sessionID: (json['session_id'] as num).toInt(),
  remainingAttempts: (json['remaining_attempts'] as num).toInt(),
);

Map<String, dynamic> _$RequestPinSessionEventToJson(
  RequestPinSessionEvent instance,
) => <String, dynamic>{
  'session_id': instance.sessionID,
  'remaining_attempts': instance.remainingAttempts,
};

PairingRequiredSessionEvent _$PairingRequiredSessionEventFromJson(
  Map<String, dynamic> json,
) => PairingRequiredSessionEvent(
  sessionID: (json['session_id'] as num).toInt(),
  pairingCode: json['pairing_code'] as String,
);

Map<String, dynamic> _$PairingRequiredSessionEventToJson(
  PairingRequiredSessionEvent instance,
) => <String, dynamic>{
  'session_id': instance.sessionID,
  'pairing_code': instance.pairingCode,
};

KeyshareEnrollmentMissingSessionEvent
_$KeyshareEnrollmentMissingSessionEventFromJson(Map<String, dynamic> json) =>
    KeyshareEnrollmentMissingSessionEvent(
      sessionID: (json['session_id'] as num).toInt(),
      schemeManagerID: json['scheme_manager_id'] as String,
    );

Map<String, dynamic> _$KeyshareEnrollmentMissingSessionEventToJson(
  KeyshareEnrollmentMissingSessionEvent instance,
) => <String, dynamic>{
  'session_id': instance.sessionID,
  'scheme_manager_id': instance.schemeManagerID,
};

KeyshareEnrollmentDeletedSessionEvent
_$KeyshareEnrollmentDeletedSessionEventFromJson(Map<String, dynamic> json) =>
    KeyshareEnrollmentDeletedSessionEvent(
      sessionID: (json['session_id'] as num).toInt(),
      schemeManagerID: json['scheme_manager_id'] as String,
    );

Map<String, dynamic> _$KeyshareEnrollmentDeletedSessionEventToJson(
  KeyshareEnrollmentDeletedSessionEvent instance,
) => <String, dynamic>{
  'session_id': instance.sessionID,
  'scheme_manager_id': instance.schemeManagerID,
};

KeyshareBlockedSessionEvent _$KeyshareBlockedSessionEventFromJson(
  Map<String, dynamic> json,
) => KeyshareBlockedSessionEvent(
  sessionID: (json['session_id'] as num).toInt(),
  schemeManagerID: json['scheme_manager_id'] as String,
  duration: (json['duration'] as num).toInt(),
);

Map<String, dynamic> _$KeyshareBlockedSessionEventToJson(
  KeyshareBlockedSessionEvent instance,
) => <String, dynamic>{
  'session_id': instance.sessionID,
  'scheme_manager_id': instance.schemeManagerID,
  'duration': instance.duration,
};

KeyshareEnrollmentIncompleteSessionEvent
_$KeyshareEnrollmentIncompleteSessionEventFromJson(Map<String, dynamic> json) =>
    KeyshareEnrollmentIncompleteSessionEvent(
      sessionID: (json['session_id'] as num).toInt(),
      schemeManagerID: json['scheme_manager_id'] as String,
    );

Map<String, dynamic> _$KeyshareEnrollmentIncompleteSessionEventToJson(
  KeyshareEnrollmentIncompleteSessionEvent instance,
) => <String, dynamic>{
  'session_id': instance.sessionID,
  'scheme_manager_id': instance.schemeManagerID,
};

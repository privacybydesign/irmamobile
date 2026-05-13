// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$NewSessionEventToJson(NewSessionEvent instance) =>
    <String, dynamic>{'request': instance.request};

RespondPreAuthorizedCodeFlowPermissionEvent
_$RespondPreAuthorizedCodeFlowPermissionEventFromJson(
  Map<String, dynamic> json,
) => RespondPreAuthorizedCodeFlowPermissionEvent(
  sessionId: (json['session_id'] as num).toInt(),
  proceed: json['proceed'] as bool,
  transactionCode: json['transaction_code'] as String?,
);

Map<String, dynamic> _$RespondPreAuthorizedCodeFlowPermissionEventToJson(
  RespondPreAuthorizedCodeFlowPermissionEvent instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'proceed': instance.proceed,
  'transaction_code': instance.transactionCode,
};

RespondAuthorizationCodeEvent _$RespondAuthorizationCodeEventFromJson(
  Map<String, dynamic> json,
) => RespondAuthorizationCodeEvent(
  sessionId: (json['session_id'] as num).toInt(),
  proceed: json['proceed'] as bool,
  code: json['code'] as String,
);

Map<String, dynamic> _$RespondAuthorizationCodeEventToJson(
  RespondAuthorizationCodeEvent instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'proceed': instance.proceed,
  'code': instance.code,
};

RespondTokenEvent _$RespondTokenEventFromJson(Map<String, dynamic> json) =>
    RespondTokenEvent(
      sessionId: (json['session_id'] as num).toInt(),
      proceed: json['proceed'] as bool,
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
    );

Map<String, dynamic> _$RespondTokenEventToJson(RespondTokenEvent instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'proceed': instance.proceed,
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
    };

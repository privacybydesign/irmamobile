// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authentication_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthenticateEvent _$AuthenticateEventFromJson(Map<String, dynamic> json) =>
    AuthenticateEvent(
      pin: json['pin'] as String,
      schemeId: json['scheme_id'] as String,
    );

Map<String, dynamic> _$AuthenticateEventToJson(AuthenticateEvent instance) =>
    <String, dynamic>{'pin': instance.pin, 'scheme_id': instance.schemeId};

AuthenticationSuccessEvent _$AuthenticationSuccessEventFromJson(
  Map<String, dynamic> json,
) => AuthenticationSuccessEvent();

Map<String, dynamic> _$AuthenticationSuccessEventToJson(
  AuthenticationSuccessEvent instance,
) => <String, dynamic>{};

AuthenticationFailedEvent _$AuthenticationFailedEventFromJson(
  Map<String, dynamic> json,
) => AuthenticationFailedEvent(
  remainingAttempts: (json['remaining_attempts'] as num).toInt(),
  blockedDuration: (json['blocked_duration'] as num).toInt(),
);

Map<String, dynamic> _$AuthenticationFailedEventToJson(
  AuthenticationFailedEvent instance,
) => <String, dynamic>{
  'remaining_attempts': instance.remainingAttempts,
  'blocked_duration': instance.blockedDuration,
};

AuthenticationErrorEvent _$AuthenticationErrorEventFromJson(
  Map<String, dynamic> json,
) => AuthenticationErrorEvent(
  error: SessionError.fromJson(json['error'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AuthenticationErrorEventToJson(
  AuthenticationErrorEvent instance,
) => <String, dynamic>{'error': instance.error};

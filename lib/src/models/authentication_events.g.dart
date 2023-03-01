// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authentication_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthenticateEvent _$AuthenticateEventFromJson(Map<String, dynamic> json) => AuthenticateEvent(
      pin: json['Pin'] as String,
      schemeId: json['SchemeID'] as String,
    );

Map<String, dynamic> _$AuthenticateEventToJson(AuthenticateEvent instance) => <String, dynamic>{
      'Pin': instance.pin,
      'SchemeID': instance.schemeId,
    };

AuthenticationSuccessEvent _$AuthenticationSuccessEventFromJson(Map<String, dynamic> json) =>
    AuthenticationSuccessEvent();

Map<String, dynamic> _$AuthenticationSuccessEventToJson(AuthenticationSuccessEvent instance) => <String, dynamic>{};

AuthenticationFailedEvent _$AuthenticationFailedEventFromJson(Map<String, dynamic> json) => AuthenticationFailedEvent(
      remainingAttempts: json['RemainingAttempts'] as int,
      blockedDuration: json['BlockedDuration'] as int,
    );

Map<String, dynamic> _$AuthenticationFailedEventToJson(AuthenticationFailedEvent instance) => <String, dynamic>{
      'RemainingAttempts': instance.remainingAttempts,
      'BlockedDuration': instance.blockedDuration,
    };

AuthenticationErrorEvent _$AuthenticationErrorEventFromJson(Map<String, dynamic> json) => AuthenticationErrorEvent(
      error: SessionError.fromJson(json['Error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthenticationErrorEventToJson(AuthenticationErrorEvent instance) => <String, dynamic>{
      'Error': instance.error,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authentication.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthenticateEvent _$AuthenticateEventFromJson(Map<String, dynamic> json) {
  return AuthenticateEvent(
    pin: json['Pin'] as String,
  );
}

Map<String, dynamic> _$AuthenticateEventToJson(AuthenticateEvent instance) => <String, dynamic>{
      'Pin': instance.pin,
    };

AuthenticationSuccessEvent _$AuthenticationSuccessEventFromJson(Map<String, dynamic> json) {
  return AuthenticationSuccessEvent();
}

Map<String, dynamic> _$AuthenticationSuccessEventToJson(AuthenticationSuccessEvent instance) => <String, dynamic>{};

AuthenticationFailedEvent _$AuthenticationFailedEventFromJson(Map<String, dynamic> json) {
  return AuthenticationFailedEvent(
    remainingAttempts: json['RemainingAttempts'] as int,
    blockedDuration: json['BlockedDuration'] as int,
  );
}

Map<String, dynamic> _$AuthenticationFailedEventToJson(AuthenticationFailedEvent instance) => <String, dynamic>{
      'RemainingAttempts': instance.remainingAttempts,
      'BlockedDuration': instance.blockedDuration,
    };

AuthenticationErrorEvent _$AuthenticationErrorEventFromJson(Map<String, dynamic> json) {
  return AuthenticationErrorEvent(
    error: json['Error'] as String,
  );
}

Map<String, dynamic> _$AuthenticationErrorEventToJson(AuthenticationErrorEvent instance) => <String, dynamic>{
      'Error': instance.error,
    };

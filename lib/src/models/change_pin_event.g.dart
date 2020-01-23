// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_pin_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChangePinEvent _$ChangePinEventFromJson(Map<String, dynamic> json) {
  return ChangePinEvent(
    oldPin: json['OldPin'] as String,
    newPin: json['NewPin'] as String,
  );
}

Map<String, dynamic> _$ChangePinEventToJson(ChangePinEvent instance) => <String, dynamic>{
      'OldPin': instance.oldPin,
      'NewPin': instance.newPin,
    };

ChangePinFailureEvent _$ChangePinFailureEventFromJson(Map<String, dynamic> json) {
  return ChangePinFailureEvent(
    schemeManagerID: json['SchemeManagerID'] as String,
    error: json['Error'] == null ? null : SessionError.fromJson(json['Error'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$ChangePinFailureEventToJson(ChangePinFailureEvent instance) => <String, dynamic>{
      'SchemeManagerID': instance.schemeManagerID,
      'Error': instance.error,
    };

ChangePinSuccessEvent _$ChangePinSuccessEventFromJson(Map<String, dynamic> json) {
  return ChangePinSuccessEvent(
    schemeManagerID: json['SchemeManagerID'] as String,
  );
}

Map<String, dynamic> _$ChangePinSuccessEventToJson(ChangePinSuccessEvent instance) => <String, dynamic>{
      'SchemeManagerID': instance.schemeManagerID,
    };

ChangePinIncorrect _$ChangePinIncorrectFromJson(Map<String, dynamic> json) {
  return ChangePinIncorrect(
    schemeManagerID: json['SchemeManagerID'] as String,
    remainingAttempts: json['RemainingAttempts'] as int,
  );
}

Map<String, dynamic> _$ChangePinIncorrectToJson(ChangePinIncorrect instance) => <String, dynamic>{
      'SchemeManagerID': instance.schemeManagerID,
      'RemainingAttempts': instance.remainingAttempts,
    };

ChangePinBlocked _$ChangePinBlockedFromJson(Map<String, dynamic> json) {
  return ChangePinBlocked(
    schemeManagerID: json['SchemeManagerID'] as String,
    timeout: json['Timeout'] as int,
  );
}

Map<String, dynamic> _$ChangePinBlockedToJson(ChangePinBlocked instance) => <String, dynamic>{
      'SchemeManagerID': instance.schemeManagerID,
      'Timeout': instance.timeout,
    };

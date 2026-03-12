// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_pin_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChangePinEvent _$ChangePinEventFromJson(Map<String, dynamic> json) =>
    ChangePinEvent(
      oldPin: json['old_pin'] as String,
      newPin: json['new_pin'] as String,
    );

Map<String, dynamic> _$ChangePinEventToJson(ChangePinEvent instance) =>
    <String, dynamic>{'old_pin': instance.oldPin, 'new_pin': instance.newPin};

ChangePinErrorEvent _$ChangePinErrorEventFromJson(Map<String, dynamic> json) =>
    ChangePinErrorEvent(
      schemeManagerID: json['scheme_manager_id'] as String,
      error: SessionError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ChangePinErrorEventToJson(
  ChangePinErrorEvent instance,
) => <String, dynamic>{
  'scheme_manager_id': instance.schemeManagerID,
  'error': instance.error,
};

ChangePinSuccessEvent _$ChangePinSuccessEventFromJson(
  Map<String, dynamic> json,
) => ChangePinSuccessEvent();

Map<String, dynamic> _$ChangePinSuccessEventToJson(
  ChangePinSuccessEvent instance,
) => <String, dynamic>{};

ChangePinFailedEvent _$ChangePinFailedEventFromJson(
  Map<String, dynamic> json,
) => ChangePinFailedEvent(
  schemeManagerID: json['scheme_manager_id'] as String,
  remainingAttempts: (json['remaining_attempts'] as num).toInt(),
  timeout: (json['timeout'] as num).toInt(),
);

Map<String, dynamic> _$ChangePinFailedEventToJson(
  ChangePinFailedEvent instance,
) => <String, dynamic>{
  'scheme_manager_id': instance.schemeManagerID,
  'remaining_attempts': instance.remainingAttempts,
  'timeout': instance.timeout,
};

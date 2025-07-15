import 'package:json_annotation/json_annotation.dart';

import 'event.dart';
import 'session.dart';

part 'change_pin_events.g.dart';

abstract class ChangePinBaseEvent extends Event {}

@JsonSerializable()
class ChangePinEvent extends ChangePinBaseEvent {
  ChangePinEvent({required this.oldPin, required this.newPin});

  @JsonKey(name: 'OldPin')
  final String oldPin;

  @JsonKey(name: 'NewPin')
  final String newPin;

  factory ChangePinEvent.fromJson(Map<String, dynamic> json) => _$ChangePinEventFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePinEventToJson(this);
}

@JsonSerializable()
class ChangePinErrorEvent extends ChangePinBaseEvent {
  ChangePinErrorEvent({
    required this.schemeManagerID,
    required this.error,
  });

  @JsonKey(name: 'SchemeManagerID')
  final String schemeManagerID;

  @JsonKey(name: 'Error')
  final SessionError error;

  factory ChangePinErrorEvent.fromJson(Map<String, dynamic> json) => _$ChangePinErrorEventFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePinErrorEventToJson(this);
}

@JsonSerializable()
class ChangePinSuccessEvent extends ChangePinBaseEvent {
  ChangePinSuccessEvent();

  factory ChangePinSuccessEvent.fromJson(Map<String, dynamic> json) => _$ChangePinSuccessEventFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePinSuccessEventToJson(this);
}

@JsonSerializable()
class ChangePinFailedEvent extends ChangePinBaseEvent {
  ChangePinFailedEvent({required this.schemeManagerID, required this.remainingAttempts, required this.timeout});

  @JsonKey(name: 'SchemeManagerID')
  final String schemeManagerID;

  @JsonKey(name: 'RemainingAttempts')
  final int remainingAttempts;

  @JsonKey(name: 'Timeout')
  final int timeout;

  factory ChangePinFailedEvent.fromJson(Map<String, dynamic> json) => _$ChangePinFailedEventFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePinFailedEventToJson(this);
}

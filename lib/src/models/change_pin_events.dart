import 'package:irmamobile/src/models/event.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:json_annotation/json_annotation.dart';

part 'change_pin_events.g.dart';

abstract class ChangePinBaseEvent extends Event {}

@JsonSerializable()
class ChangePinEvent extends ChangePinBaseEvent {
  ChangePinEvent({this.oldPin, this.newPin});

  @JsonKey(name: 'OldPin')
  String oldPin;

  @JsonKey(name: 'NewPin')
  String newPin;

  factory ChangePinEvent.fromJson(Map<String, dynamic> json) => _$ChangePinEventFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePinEventToJson(this);
}

@JsonSerializable()
class ChangePinErrorEvent extends ChangePinBaseEvent {
  ChangePinErrorEvent({
    this.schemeManagerID,
    this.error,
  });

  @JsonKey(name: 'SchemeManagerID')
  String schemeManagerID;

  @JsonKey(name: 'Error')
  SessionError error;

  factory ChangePinErrorEvent.fromJson(Map<String, dynamic> json) => _$ChangePinErrorEventFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePinErrorEventToJson(this);
}

@JsonSerializable()
class ChangePinSuccessEvent extends ChangePinBaseEvent {
  ChangePinSuccessEvent({this.schemeManagerID});

  @JsonKey(name: 'SchemeManagerID')
  String schemeManagerID;

  factory ChangePinSuccessEvent.fromJson(Map<String, dynamic> json) => _$ChangePinSuccessEventFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePinSuccessEventToJson(this);
}

@JsonSerializable()
class ChangePinFailedEvent extends ChangePinBaseEvent {
  ChangePinFailedEvent({this.schemeManagerID, this.remainingAttempts, this.timeout});

  @JsonKey(name: 'SchemeManagerID')
  String schemeManagerID;

  @JsonKey(name: 'RemainingAttempts')
  int remainingAttempts;

  @JsonKey(name: 'Timeout')
  int timeout;

  factory ChangePinFailedEvent.fromJson(Map<String, dynamic> json) => _$ChangePinFailedEventFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePinFailedEventToJson(this);
}

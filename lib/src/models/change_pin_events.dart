import 'package:irmamobile/src/models/event.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:json_annotation/json_annotation.dart';

part 'change_pin_events.g.dart';

@JsonSerializable()
class ChangePinEvent extends Event {
  ChangePinEvent({this.oldPin, this.newPin});

  @JsonKey(name: 'OldPin')
  String oldPin;

  @JsonKey(name: 'NewPin')
  String newPin;

  factory ChangePinEvent.fromJson(Map<String, dynamic> json) => _$ChangePinEventFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePinEventToJson(this);
}

@JsonSerializable()
class ChangePinFailureEvent extends Event {
  ChangePinFailureEvent({
    this.schemeManagerID,
    this.error,
  });

  @JsonKey(name: 'SchemeManagerID')
  String schemeManagerID;

  @JsonKey(name: 'Error')
  SessionError error;

  factory ChangePinFailureEvent.fromJson(Map<String, dynamic> json) => _$ChangePinFailureEventFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePinFailureEventToJson(this);
}

@JsonSerializable()
class ChangePinSuccessEvent extends Event {
  ChangePinSuccessEvent({this.schemeManagerID});

  @JsonKey(name: 'SchemeManagerID')
  String schemeManagerID;

  factory ChangePinSuccessEvent.fromJson(Map<String, dynamic> json) => _$ChangePinSuccessEventFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePinSuccessEventToJson(this);
}

@JsonSerializable()
class ChangePinIncorrect extends Event {
  ChangePinIncorrect({this.schemeManagerID, this.remainingAttempts});

  @JsonKey(name: 'SchemeManagerID')
  String schemeManagerID;

  @JsonKey(name: 'RemainingAttempts')
  int remainingAttempts;

  factory ChangePinIncorrect.fromJson(Map<String, dynamic> json) => _$ChangePinIncorrectFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePinIncorrectToJson(this);
}

@JsonSerializable()
class ChangePinBlocked extends Event {
  ChangePinBlocked({this.schemeManagerID, this.timeout});

  @JsonKey(name: 'SchemeManagerID')
  String schemeManagerID;

  @JsonKey(name: 'Timeout')
  int timeout;

  factory ChangePinBlocked.fromJson(Map<String, dynamic> json) => _$ChangePinBlockedFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePinBlockedToJson(this);
}

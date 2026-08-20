import "package:json_annotation/json_annotation.dart";

import "event.dart";
import "session.dart";

part "change_pin_events.g.dart";

abstract class ChangePinBaseEvent extends Event {}

@JsonSerializable(fieldRename: FieldRename.snake)
class ChangePinEvent extends ChangePinBaseEvent {
  ChangePinEvent({required this.oldPin, required this.newPin});

  final String oldPin;

  final String newPin;

  factory ChangePinEvent.fromJson(Map<String, dynamic> json) =>
      _$ChangePinEventFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePinEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ChangePinErrorEvent extends ChangePinBaseEvent {
  ChangePinErrorEvent({required this.schemeManagerID, required this.error});

  @JsonKey(name: "scheme_manager_id")
  final String schemeManagerID;

  final SessionError error;

  factory ChangePinErrorEvent.fromJson(Map<String, dynamic> json) =>
      _$ChangePinErrorEventFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePinErrorEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ChangePinSuccessEvent extends ChangePinBaseEvent {
  ChangePinSuccessEvent();

  factory ChangePinSuccessEvent.fromJson(Map<String, dynamic> json) =>
      _$ChangePinSuccessEventFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePinSuccessEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ChangePinFailedEvent extends ChangePinBaseEvent {
  ChangePinFailedEvent({
    required this.schemeManagerID,
    required this.remainingAttempts,
    required this.timeout,
  });

  @JsonKey(name: "scheme_manager_id")
  final String schemeManagerID;

  final int remainingAttempts;

  final int timeout;

  factory ChangePinFailedEvent.fromJson(Map<String, dynamic> json) =>
      _$ChangePinFailedEventFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePinFailedEventToJson(this);
}

import "package:json_annotation/json_annotation.dart";

import "event.dart";

part "native_events.g.dart";

@JsonSerializable(createFactory: false)
class AppReadyEvent extends Event {
  AppReadyEvent();

  Map<String, dynamic> toJson() => _$AppReadyEventToJson(this);
}

/// Sent by native in direct response to [AppReadyEvent], right after any
/// initial-URL [HandleURLEvent]. Its arrival tells the app the launch handshake
/// is complete and any universal-link pointer has already been queued, so the
/// lock screen can safely decide whether to auto-fire biometric.
@JsonSerializable(createToJson: false)
class AppReadyAckEvent extends Event {
  AppReadyAckEvent();

  factory AppReadyAckEvent.fromJson(Map<String, dynamic> json) =>
      _$AppReadyAckEventFromJson(json);
}

@JsonSerializable(createFactory: false)
class AndroidSendToBackgroundEvent extends Event {
  AndroidSendToBackgroundEvent();

  Map<String, dynamic> toJson() => _$AndroidSendToBackgroundEventToJson(this);
}

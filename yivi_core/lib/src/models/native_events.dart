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

/// The warm-resume twin of [AppReadyAckEvent]. Sent by native from the resume
/// callback (`applicationDidBecomeActive` / Android `onResume`), right after any
/// link's [HandleURLEvent] and on the same bridge channel, so FIFO delivery
/// means Dart has already queued the pointer by the time this arrives. Emitted
/// only after a real backgrounding, so the boot activation can't pre-empt the
/// cold-start [AppReadyAckEvent]. Closes the carrier window on resume, letting
/// the lock screen decide whether to auto-fire biometric.
@JsonSerializable(createToJson: false)
class ResumeAckEvent extends Event {
  ResumeAckEvent();

  factory ResumeAckEvent.fromJson(Map<String, dynamic> json) =>
      _$ResumeAckEventFromJson(json);
}

@JsonSerializable(createFactory: false)
class AndroidSendToBackgroundEvent extends Event {
  AndroidSendToBackgroundEvent();

  Map<String, dynamic> toJson() => _$AndroidSendToBackgroundEventToJson(this);
}

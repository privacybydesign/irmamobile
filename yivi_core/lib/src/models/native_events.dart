import "package:json_annotation/json_annotation.dart";

import "event.dart";

part "native_events.g.dart";

@JsonSerializable(createFactory: false)
class AppReadyEvent extends Event {
  AppReadyEvent({required this.locale});

  /// The effective app language (a bare language code such as "nl") the Go
  /// client is constructed with, so text and logos resolve correctly from the
  /// first pull. The native plugin reads it from this payload.
  final String locale;

  Map<String, dynamic> toJson() => _$AppReadyEventToJson(this);
}

/// Changes the effective app language in the Go client at runtime. The Go
/// handler re-resolves and re-dispatches credentials; the app follows this
/// with a [LoadLogsEvent] to reset the activity-log cache.
@JsonSerializable(createFactory: false)
class SetLocaleEvent extends Event {
  SetLocaleEvent({required this.locale});

  final String locale;

  Map<String, dynamic> toJson() => _$SetLocaleEventToJson(this);
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

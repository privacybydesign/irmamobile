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

/// Tells the Activity that opened this engine to answer a Digital Credentials
/// API request that the user is done with it, so it can hand its result back and
/// close.
///
/// Distinct from [AndroidSendToBackgroundEvent], which means the same thing for
/// the wallet's own Activity. It cannot be reused here: backgrounding leaves the
/// caller waiting on a result that is never sent, and the browser's request hangs
/// until it times out.
///
/// The result itself was already set when the response was produced. This only
/// says when to show it — which is after the user has read what was shared, not
/// the instant the wallet finished working.
@JsonSerializable(createFactory: false)
class AndroidFinishDcApiPresentationEvent extends Event {
  AndroidFinishDcApiPresentationEvent();

  Map<String, dynamic> toJson() =>
      _$AndroidFinishDcApiPresentationEventToJson(this);
}

/// An unlock this process already completed, carried into a freshly started
/// engine.
///
/// Sent only after a Digital Credentials API presentation ended, which cannot
/// happen before the user unlocked: the session starts behind the lock screen.
/// So it reports a fact about this process rather than granting anything —
/// somebody authenticated here, moments ago, and is now being handed to the
/// wallet as part of the same continuous action.
///
/// The lock lives per Flutter engine ([IrmaRepository] seeds it locked), and a
/// presentation runs in a second one. Without this the user unlocks to approve a
/// disclosure and unlocks again seconds later to look at the record of it.
///
/// See UnlockHandover on the native side for how narrowly it is fenced.
@JsonSerializable(createToJson: false)
class UnlockHandoverEvent extends Event {
  UnlockHandoverEvent();

  factory UnlockHandoverEvent.fromJson(Map<String, dynamic> json) =>
      _$UnlockHandoverEventFromJson(json);
}

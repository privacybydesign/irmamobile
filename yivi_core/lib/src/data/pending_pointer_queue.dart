import "package:rxdart/rxdart.dart";

import "../models/event.dart";
import "../models/handle_url_event.dart";
import "../models/native_events.dart";
import "../models/session.dart";
import "../models/session_events.dart";
import "../sentry/sentry.dart";

/// The session or e-mail link waiting to be started, and whether the launch
/// handshake is over (ADR 0004, CONTEXT "Carrier Window").
///
/// A link that opens the app is queued here; the home screen starts it once
/// the app is unlocked, and the lock screen keeps biometric back while one
/// waits.
class PendingPointerQueue {
  PendingPointerQueue({
    required Future<void> Function(String url) onAuthCallback,
    required void Function() closeInAppBrowser,
  }) : _onAuthCallback = onAuthCallback,
       _closeInAppBrowser = closeInAppBrowser;

  /// Hands the issuer login's callback to its session.
  final Future<void> Function(String url) _onAuthCallback;

  /// Closes the in-app browser a link was opened from.
  final void Function() _closeInAppBrowser;

  final _pending = BehaviorSubject<Pointer?>.seeded(null);

  // Flips true once native acknowledges the launch handshake (AppReadyAckEvent),
  // by which point any initial-URL pointer has already been queued. Seeded false
  // so the lock screen holds off its cold-start biometric auto-scan until the
  // launch URL (if any) is known — see the AppReadyAckEvent handler.
  final _startupResolved = BehaviorSubject<bool>.seeded(false);

  /// The queued pointer, null when none waits.
  Stream<Pointer?> get pending => _pending.stream;

  /// The queued pointer now. Synchronous companion to [pending] for callers
  /// that must read the latest value without awaiting the stream: the
  /// biometric backstop refuses an unlock while a session waits.
  Pointer? get current => _pending.value;

  /// Whether the native launch handshake has completed, so any universal-link
  /// pointer the app was opened with is already queued (see [pending]). The
  /// lock screen waits for this before auto-firing biometric on a cold start.
  Stream<bool> get startupResolved => _startupResolved.stream;

  /// Queues [pointer] for the home screen to pick up once the app is
  /// unlocked: from the scanner, the lock screen's scanner, a test session.
  void put(Pointer pointer) => _pending.add(pointer);

  /// Drops the queued pointer: cancelled on the lock screen, taken by the
  /// enrollment's e-mail step, handled.
  void clear() => _pending.add(null);

  /// A link that opened the app, the end of the launch handshake, and a
  /// session that started (which clears the queue, in the same delivery that
  /// marks the session in flight).
  Future<void> onEvent(Event event) async {
    switch (event) {
      case HandleURLEvent(:final url):
        try {
          if (url.startsWith("app.yivi.open://auth-callback") ||
              url.startsWith("https://open.yivi.app/-/auth-callback")) {
            await _onAuthCallback(url);
            return;
          }

          final pointer =
              await _emailCodePointer(url) ?? Pointer.fromString(url);
          _pending.add(pointer);
          _closeInAppBrowser();
        } on MissingPointer catch (e, stackTrace) {
          reportError(e, stackTrace);
        }
      case AppReadyAckEvent():
        // Native's acknowledgement that the launch handshake is done. It is
        // sent right AFTER any initial-URL `HandleURLEvent`, so on a cold
        // start started by a universal link the pending pointer above has
        // already been queued by the time this flips `startupResolved` true.
        // The lock screen gates its biometric auto-scan on this, so biometric
        // can never win the race against the link and unlock the app before
        // the session pointer is known.
        _startupResolved.add(true);
      case NewSessionEvent():
        _pending.add(null);
      default:
    }
  }

  /// The e-mail code link in [url], or null when it is not one. Only a user
  /// who asked for a code gets such a link.
  Future<EmailCodePointer?> _emailCodePointer(String url) async =>
      EmailCodePointer.tryParse(url);

  Future<void> close() =>
      Future.wait([_pending.close(), _startupResolved.close()]);
}

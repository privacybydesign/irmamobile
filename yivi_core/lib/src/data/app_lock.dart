import "package:rxdart/rxdart.dart";

import "../models/authentication_events.dart";
import "../models/clear_all_data_event.dart";
import "../models/delete_keyshare_tokens_event.dart";
import "../models/enrollment_events.dart";
import "../models/error_event.dart";
import "../models/event.dart";
import "irma_preferences.dart";

/// Whether the app shows the lock screen, until when wrong PINs block it,
/// and why the next lock screen should not scan on its own.
class AppLock {
  AppLock({
    required void Function(Event event) dispatch,
    required IrmaPreferences preferences,
    required String defaultKeyshareScheme,
  }) : _dispatch = dispatch,
       _preferences = preferences,
       _scheme = defaultKeyshareScheme;

  /// Sends an event to the bridge and to the app's own listeners.
  final void Function(Event event) _dispatch;
  final IrmaPreferences _preferences;
  final String _scheme;

  final _locked = BehaviorSubject<bool>.seeded(true);
  final _blocked = BehaviorSubject<DateTime?>();
  final _authentication = PublishSubject<AuthenticationEvent>();

  /// Whether the lock screen shows; locked from the start. A value is
  /// passed on only when it changes.
  Stream<bool> get locked => _locked.distinct().asBroadcastStream();

  bool get isLocked => _locked.value;

  /// Until when wrong PINs block an unlock; null when nothing blocks.
  /// Nothing before the first lock.
  Stream<DateTime?> get blockedUntil => _blocked.stream;

  // Set by the More tab's Log out, so the next lock screen shows the PIN pad
  // instead of scanning on its own. One-shots consumed by the lock screen:
  // an idle lock leaves them false and still scans.
  bool _autoScanSuppressed = false;
  bool _confirmLogout = false;

  /// Drops irmago's in-memory keyshare token, then locks: the next session
  /// must authenticate with the PIN again. A biometric unlock alone won't
  /// restore the token (only a PIN does), so the token goes first.
  void lock({DateTime? unblockTime}) {
    _dispatch(DeleteKeyshareTokensEvent());
    _locked.add(true);
    _blocked.add(unblockTime);
  }

  /// The More tab's Log out: locks, and the lock screen that follows
  /// neither scans on its own nor stays silent about why it shows.
  void logOut() {
    _autoScanSuppressed = true;
    _confirmLogout = true;
    lock();
  }

  /// Whether the next automatic biometric scan should be skipped; true once
  /// after a logout.
  bool consumeLogoutAutoScanSuppressed() {
    final suppressed = _autoScanSuppressed;
    _autoScanSuppressed = false;
    return suppressed;
  }

  /// Whether the lock screen should say the user logged out; true once
  /// after a logout.
  bool consumeLogoutConfirmation() {
    final confirm = _confirmLogout;
    _confirmLogout = false;
    return confirm;
  }

  /// Checks [pin] with the keyshare server, which refreshes the keyshare
  /// token, and answers with the result. A success unlocks.
  Future<AuthenticationEvent> unlock(String pin) {
    _dispatch(AuthenticateEvent(pin: pin, schemeId: _scheme));

    return _authentication.where((event) {
      switch (event) {
        case AuthenticationSuccessEvent():
          _preferences.longPin.set(pin.length != 5);
          return true;
        case AuthenticationFailedEvent() || AuthenticationErrorEvent():
          return true;
        default:
          return false;
      }
    }).first;
  }

  /// Unlocks the app shell only (after biometric authentication), WITHOUT
  /// authenticating against the keyshare server: the first session started
  /// afterwards still hits `SessionStatus.requestPin` and asks for the PIN.
  void unlockLocally() => _locked.add(false);

  /// Unlocked with nothing blocking: a new enrollment, or all data cleared.
  void clear() {
    _locked.add(false);
    _blocked.add(null);
  }

  /// A PIN that was right unlocks; a fatal error unlocks so its screen
  /// shows; an unenrolled default scheme and a reset leave nothing to lock.
  void onEvent(Event event) {
    switch (event) {
      case AuthenticationEvent():
        _authentication.add(event);
        if (event is AuthenticationSuccessEvent) clear();
      case ErrorEvent(fatal: true):
        _locked.add(false);
      case EnrollmentStatusEvent()
          when event.unenrolledSchemeManagerIds.contains(_scheme):
        _locked.add(false);
      case ClearAllDataEvent():
        clear();
      default:
    }
  }

  Future<void> close() =>
      Future.wait([_locked.close(), _blocked.close(), _authentication.close()]);
}

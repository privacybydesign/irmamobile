import "dart:io";

import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:local_auth/local_auth.dart";
import "package:material_ui/material_ui.dart";

import "../../../package_name.dart";
import "../../models/session.dart";
import "../../providers/has_in_flight_session_provider.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/pending_pointer_provider.dart";
import "../../providers/preferences_provider.dart";
import "../../providers/startup_url_resolved_provider.dart";
import "../../providers/waiting_request_provider.dart";
import "../../theme/theme.dart";
import "../../util/i18n.dart";
import "../../util/navigation.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_close_button.dart";
import "../error/session_error_screen.dart";
import "providers/biometric_provider.dart";
import "providers/pin_unlock_provider.dart";
import "widgets/waiting_request_announcement.dart";
import "yivi_pin_screen.dart";

/// Builds the biometric button glyph for [type], tinted to the keypad colour:
/// the Face ID asset for face unlock on iOS, the Material face icon for face
/// unlock on Android, and the Material fingerprint icon otherwise (Touch ID,
/// fingerprint sensors, unknown/null).
Widget _biometricGlyph(BuildContext context, BiometricType? type) {
  final color = IrmaTheme.of(context).secondary;
  if (type == BiometricType.face) {
    // Face ID's branded glyph is Apple-specific — only use it on iOS.
    return Platform.isIOS
        ? SvgPicture.asset(
            yiviAsset("ui/face_id.svg"),
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          )
        : Icon(Icons.face, color: color);
  }
  return Icon(Icons.fingerprint, color: color);
}

class PinScreen extends ConsumerStatefulWidget {
  final Function() onAuthenticated;
  final Widget? leading;

  /// Optional override for the "Forgot PIN?" link. The default uses
  /// `context.pushResetPinScreen()`, which goes via GoRouter. Hosts
  /// that mount `PinScreen` outside the GoRouter scope (e.g. the
  /// `LockGate` overlay's local Navigator) should pass a callback
  /// that navigates through the GoRouter instance directly.
  final void Function()? onForgotPin;

  /// Whether to offer biometric unlock here. Only the app-unlock flow (the
  /// LockGate overlay) sets this; the modal re-auth flow leaves it false so
  /// biometric never substitutes for an explicit PIN confirmation.
  final bool allowBiometric;

  const PinScreen({
    super.key,
    required this.onAuthenticated,
    this.leading,
    this.onForgotPin,
    this.allowBiometric = false,
  });

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen>
    with WidgetsBindingObserver {
  // Bumped on a wrong/blocked attempt to remount YiviPinScreen with an empty
  // buffer — clears the entered digits and their dots. Same pattern as
  // SessionPinEntryScreen.
  int _resetNonce = 0;

  // "Scan on launch": guards the one auto-fire of the biometric prompt per
  // foreground. Set true once fired; stays true after a cancel/fail so we don't
  // re-prompt in a loop within the same foreground. Re-armed (set false) when
  // the app is backgrounded (see [didChangeAppLifecycleState]) so re-opening
  // the app scans again, and reset for free whenever LockGate remounts a fresh
  // PinScreen on a new lock appearance.
  bool _autoTriggered = false;

  // True while a biometric prompt is on screen. On some platforms the prompt
  // itself backgrounds the app; this stops the lifecycle re-arm below from
  // firing a second scan while one is already running (which would loop on
  // cancel).
  bool _scanInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    // Re-arm on a real backgrounding (`paused`) — not the transient `inactive`
    // the biometric prompt causes, and not while a scan is already running.
    // On `resumed`, rebuild so the auto-trigger guard in build() re-evaluates
    // and fires the scan for the re-opened app.
    if (state == AppLifecycleState.paused && !_scanInProgress) {
      _autoTriggered = false;
      // A re-open is fresh intent to use the app, so drop the logout
      // suppression too: it only covers the lock screen shown directly after an
      // explicit logout, not a later re-open. No-op if already consumed.
      ref.read(irmaRepositoryProvider).consumeBiometricAutoUnlockSuppressed();
    } else if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  void _goToSessionErrorScreen(SessionError? error) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SessionErrorScreen(
          error: error,
          onTapClose: Navigator.of(context).pop,
        ),
      ),
    );
  }

  void _handleStateChange(PinUnlockState state) {
    if (state.authenticated) {
      HapticFeedback.mediumImpact();
      widget.onAuthenticated();
      return;
    }
    // A wrong PIN or a block is said on the screen itself (see build): the
    // entry is cleared, the dots ring red and the line says what happened.
    if (state.pinInvalid) {
      HapticFeedback.heavyImpact();
      if (mounted) setState(() => _resetNonce++);
    } else if (state.error != null) {
      HapticFeedback.heavyImpact();
      _goToSessionErrorScreen(state.error);
    }
  }

  Future<void> _biometricUnlock() async {
    final reason = FlutterI18n.translate(context, "pin.biometric_reason");
    // On success the service flips appLocked locally (no keyshare), which
    // drops the lock overlay; sessions still require the PIN.
    _scanInProgress = true;
    try {
      await ref
          .read(biometricServiceProvider)
          .authenticateAndUnlock(localizedReason: reason);
    } finally {
      _scanInProgress = false;
    }
  }

  // Cancel a waiting session from the lock screen: confirm, then clear the
  // queued pointer AND dismiss any in-flight session behind the lock (one a link
  // kicked off before the app idle-locked, at any non-terminal status — not just
  // requestPermission). Both revert the screen to normal unlock — biometric
  // reappears once no session is in flight.
  Future<void> _confirmCancelPending(BuildContext context) async {
    final confirmed = await confirmStopWaitingRequest(
      context,
      ref.read(waitingRequestProvider).value,
    );
    if (confirmed && mounted) {
      final repo = ref.read(irmaRepositoryProvider);
      repo.setPendingPointer(null);
      repo.dismissAllInFlightSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PinUnlockState>(
      pinUnlockProvider,
      (_, next) => _handleStateChange(next),
    );

    final state = ref.watch(pinUnlockProvider);

    // Hide pin screen once authenticated.
    if (state.authenticated) return Container();

    final blockedFor = ref.watch(pinBlockedForProvider).value ?? Duration.zero;
    final blocked = blockedFor.inSeconds > 0;

    final biometricAvailable =
        ref.watch(biometricAvailableProvider).value ?? false;
    final biometricEnabled = ref.watch(biometricEnabledProvider).value ?? false;
    // Hide biometric when a session is pending: biometric unlock doesn't refresh
    // the keyshare token, so the session would still demand the PIN — a second
    // prompt. Entering the PIN here refreshes the token and the session proceeds.
    final hasPendingSession = ref.watch(pendingPointerProvider) != null;
    // Also hide it while a session is in flight. If the app was unlocked when it
    // went to the background, a link arriving then starts the session
    // immediately (clearing the pending pointer) before the resume idle-lock
    // re-locks — so `hasPendingSession` is already false by the time this lock
    // screen builds. That in-flight session needs the keyshare token, which the
    // idle-lock cleared, so it must be admitted by PIN, not biometric (#654).
    final hasInFlightSession = ref.watch(hasInFlightSessionProvider);
    // A pending pointer or an in-flight session both mean "a session is waiting
    // behind this lock" — used to hide biometric and to show the ✕ that cancels
    // it and returns to the normal unlock screen.
    final hasSession = hasPendingSession || hasInFlightSession;
    // Hold biometric back until native has acknowledged the launch handshake.
    // On a cold start opened by a universal link, the session pointer is queued
    // just before this flips true, so by the time biometric is allowed
    // `hasPendingSession` already reflects it and hides biometric. Without this
    // gate the biometric auto-scan could win the race and unlock the app before
    // the pointer arrived, letting a link session ride in on a biometric-only
    // unlock (issue #644). Once resolved it stays true, so later idle-locks
    // auto-scan normally.
    final startupUrlResolved = ref.watch(startupUrlResolvedProvider);
    // Hide biometric while blocked — otherwise it would bypass the temporary
    // lockout that the wrong-PIN rate limiter just imposed.
    final showBiometric =
        widget.allowBiometric &&
        biometricAvailable &&
        biometricEnabled &&
        !blocked &&
        !hasSession &&
        startupUrlResolved;
    final biometricType = ref.watch(biometricTypeProvider).value;

    // "Scan on launch": fire the biometric prompt automatically the first time
    // the lock screen is shown with biometric allowed. `.value ?? false` means
    // it waits for the providers to resolve on cold start rather than firing
    // early. Reuses `showBiometric`, so blocked/pending-session/unavailable and
    // the unresolved-launch-URL window are already excluded. On cancel/fail
    // nothing happens and `_autoTriggered` stays true — the user falls back to
    // the PIN pad or the manual button.
    final biometricImmediate =
        ref.watch(biometricImmediateProvider).value ?? false;
    if (showBiometric && biometricImmediate && !_autoTriggered) {
      _autoTriggered = true;
      final repo = ref.read(irmaRepositoryProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Skip the auto-scan if this lock followed an explicit logout; the
        // one-shot flag is consumed so a later idle-lock auto-scans normally.
        if (repo.consumeBiometricAutoUnlockSuppressed()) return;
        _biometricUnlock();
      });
    }

    // A request waits behind the lock: who it is from and what they want
    // take the logo's place, and the heading says what the PIN is for.
    final waiting = hasSession ? ref.watch(waitingRequestProvider).value : null;

    return YiviPinScaffold(
      appBar: IrmaAppBar(
        titleString: "",
        // Hide the leading button (the lock screen's QR scanner) while a session
        // is waiting — pending or in flight — scanning another is pointless; the
        // user should just enter their PIN.
        leading: hasSession ? null : widget.leading,
        // When a session is waiting, offer a trailing ✕ to cancel it and return
        // to the normal unlock screen.
        // PopScope here if hardware-back parity is ever requested.
        actions: hasSession
            ? [IrmaCloseButton(onTap: () => _confirmCancelPending(context))]
            : const [],
      ),
      // Only the spinner while the PIN is being verified.
      body: UnlockPinEntry(
        waiting: waiting,
        busy: state.authenticateInProgress,
        resetNonce: _resetNonce,
        onForgotPin: widget.onForgotPin ?? context.pushResetPinScreen,
        onBiometricUnlock: showBiometric ? _biometricUnlock : null,
        biometricGlyph: showBiometric
            ? _biometricGlyph(context, biometricType)
            : null,
      ),
    );
  }
}

/// The PIN pad of the app's unlock ([pinUnlockProvider]), on the lock
/// screen and in the lock screen's scanner sheet: the waiting request (if
/// any) over it, the tries left or the block under the title, and a short
/// PIN sent as soon as it is complete. While [busy] only a spinner shows;
/// the pad comes back with an empty buffer when [resetNonce] changes (after
/// a wrong PIN).
class UnlockPinEntry extends ConsumerWidget {
  final WaitingRequest? waiting;
  final bool busy;
  final int resetNonce;
  final bool showMark;

  /// In the middle of the room between the bar and the keypad.
  final bool centreUpper;
  final VoidCallback onForgotPin;
  final VoidCallback? onBiometricUnlock;
  final Widget? biometricGlyph;

  const UnlockPinEntry({
    super.key,
    required this.waiting,
    required this.busy,
    required this.resetNonce,
    this.showMark = true,
    this.centreUpper = false,
    required this.onForgotPin,
    this.onBiometricUnlock,
    this.biometricGlyph,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pinUnlockProvider);
    final maxPinSize = (ref.watch(longPinProvider).value ?? false)
        ? longPinSize
        : shortPinSize;
    final blockedFor = ref.watch(pinBlockedForProvider).value ?? Duration.zero;
    final blocked = blockedFor.inSeconds > 0;
    final enabled = !blocked && !busy;
    // A wrong PIN or a block, said in the line under the title.
    final line = pinStateLine(context, state, blockedFor);
    final waiting = this.waiting;

    void submit(String pin) => ref.read(pinUnlockProvider.notifier).unlock(pin);

    return Stack(
      alignment: Alignment.center,
      children: [
        if (!busy)
          KeyedSubtree(
            key: ValueKey(resetNonce),
            child: YiviPinScreen(
              instruction: waiting != null
                  ? context.tr(waitingLineKey(waiting))
                  : blocked
                  ? context.tr("pin.blocked_title")
                  : context.tr("pin.subtitle"),
              header: waiting == null
                  ? null
                  : WaitingRequestAnnouncement(request: waiting),
              showMark: showMark,
              // Under the announcement (the heading) a quiet line, the
              // block well clear of the keypad.
              instructionStyle: waiting == null
                  ? PinInstructionStyle.heading
                  : PinInstructionStyle.line,
              upperGap: waiting == null ? 40 : 48,
              centreUpper: centreUpper,
              detail: line?.text,
              detailKind: line == null
                  ? PinDetailKind.info
                  : PinDetailKind.error,
              detailClock: blocked,
              pinError: line != null && !blocked,
              maxPinSize: maxPinSize,
              submitLabel: "pin.unlock",
              onSubmit: enabled ? submit : (_) {},
              enabled: enabled,
              onForgotPin: onForgotPin,
              onBiometricUnlock: onBiometricUnlock,
              biometricGlyph: biometricGlyph,
              listener: (context, pinState) {
                if (maxPinSize == shortPinSize &&
                    pinState.pin.length == maxPinSize &&
                    enabled) {
                  submit(pinState.toString());
                }
              },
            ),
          ),
        if (busy) const CircularProgressIndicator(),
      ],
    );
  }
}

/// What the line under the title says after a wrong PIN or during a block:
/// the tries left, or how long until the next try. Null when neither.
({String text})? pinStateLine(
  BuildContext context,
  PinUnlockState state,
  Duration blockedFor,
) {
  if (blockedFor.inSeconds > 0) {
    return (text: pinTryAgainIn(context, blockedFor));
  }
  final left = state.remainingAttempts;
  if (state.pinInvalid && left != null && left > 0) {
    return (text: FlutterI18n.plural(context, "pin.wrong.attempts", left));
  }
  return null;
}

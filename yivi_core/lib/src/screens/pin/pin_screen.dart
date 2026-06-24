import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:local_auth/local_auth.dart";

import "../../../package_name.dart";
import "../../models/session.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/pending_pointer_provider.dart";
import "../../providers/preferences_provider.dart";
import "../../theme/theme.dart";
import "../../util/navigation.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_close_button.dart";
import "../../widgets/irma_confirmation_dialog.dart";
import "../../widgets/pin_common/format_blocked_for.dart";
import "../../widgets/pin_common/pin_wrong_attempts.dart";
import "../../widgets/pin_common/pin_wrong_blocked.dart";
import "../error/session_error_screen.dart";
import "providers/biometric_provider.dart";
import "providers/pin_unlock_provider.dart";
import "yivi_pin_screen.dart";

/// Builds the biometric button glyph for [type], tinted to the keypad colour:
/// the Face ID asset for face unlock, the Material fingerprint icon otherwise
/// (Touch ID, fingerprint sensors, unknown/null).
Widget _biometricGlyph(BuildContext context, BiometricType? type) {
  final color = IrmaTheme.of(context).secondary;
  if (type == BiometricType.face) {
    return SvgPicture.asset(
      yiviAsset("ui/face_id.svg"),
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
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

class _PinScreenState extends ConsumerState<PinScreen> {
  // Bumped on a wrong/blocked attempt to remount YiviPinScreen with an empty
  // buffer — clears the entered digits and their dots. Same pattern as
  // SessionPinEntryScreen.
  int _resetNonce = 0;

  void _showWrongAttemptsDialog(int attemptsRemaining) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => PinWrongAttemptsDialog(
        attemptsRemaining: attemptsRemaining,
        onClose: Navigator.of(context).pop,
      ),
    );
  }

  void _showBlockedDialog(int secondsBlocked) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => PinWrongBlockedDialog(blocked: secondsBlocked),
    );
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
    if (state.pinInvalid) {
      HapticFeedback.heavyImpact();
      if (mounted) setState(() => _resetNonce++);
      final secondsBlocked =
          state.blockedUntil?.difference(DateTime.now()).inSeconds ?? 0;
      if (state.remainingAttempts != null && state.remainingAttempts! > 0) {
        _showWrongAttemptsDialog(state.remainingAttempts!);
      } else if (secondsBlocked > 0) {
        _showBlockedDialog(secondsBlocked);
      }
    } else if (state.error != null) {
      HapticFeedback.heavyImpact();
      _goToSessionErrorScreen(state.error);
    }
  }

  Future<void> _biometricUnlock() async {
    final reason = FlutterI18n.translate(context, "pin.biometric_reason");
    // On success the service flips appLocked locally (no keyshare), which
    // drops the lock overlay; sessions still require the PIN.
    await ref
        .read(biometricServiceProvider)
        .authenticateAndUnlock(localizedReason: reason);
  }

  // Cancel a pending session from the lock screen: confirm, then clear the
  // queued pointer. Nothing started server-side yet, so this is a local clear —
  // the screen reverts to normal unlock and the user can re-scan.
  Future<void> _confirmCancelPending(BuildContext context) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (_) => const IrmaConfirmationDialog(
            titleTranslationKey: "pin.cancel_session_dialog.title",
            contentTranslationKey: "pin.cancel_session_dialog.explanation",
            confirmTranslationKey: "pin.cancel_session_dialog.confirm",
            cancelTranslationKey: "pin.cancel_session_dialog.decline",
          ),
        ) ??
        false;
    if (confirmed && mounted) {
      ref.read(irmaRepositoryProvider).setPendingPointer(null);
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

    final maxPinSize = (ref.watch(longPinProvider).value ?? false)
        ? longPinSize
        : shortPinSize;

    final blockedFor = ref.watch(pinBlockedForProvider).value ?? Duration.zero;
    final blocked = blockedFor.inSeconds > 0;
    final enabled = !blocked && !state.authenticateInProgress;

    final biometricAvailable =
        ref.watch(biometricAvailableProvider).value ?? false;
    final biometricEnabled = ref.watch(biometricEnabledProvider).value ?? false;
    // Hide biometric when a session is pending: biometric unlock doesn't refresh
    // the keyshare token, so the session would still demand the PIN — a second
    // prompt. Entering the PIN here refreshes the token and the session proceeds.
    final hasPendingSession = ref.watch(pendingPointerProvider) != null;
    // Hide biometric while blocked — otherwise it would bypass the temporary
    // lockout that the wrong-PIN rate limiter just imposed.
    final showBiometric =
        widget.allowBiometric &&
        biometricAvailable &&
        biometricEnabled &&
        !blocked &&
        !hasPendingSession;
    final biometricType = ref.watch(biometricTypeProvider).value;

    var subtitle = FlutterI18n.translate(context, "pin.subtitle");
    if (blockedFor.inSeconds > 0) {
      final blockedText = FlutterI18n.translate(
        context,
        "pin_common.blocked_for",
      );
      subtitle = "$blockedText ${formatBlockedFor(context, blockedFor)}";
    }

    void submit(String pin) => ref.read(pinUnlockProvider.notifier).unlock(pin);

    return YiviPinScaffold(
      appBar: IrmaAppBar(
        titleString: "",
        hasBorder: false,
        // Hide the leading button (the lock screen's QR scanner) while a session
        // is pending — scanning another is pointless; the user should just enter
        // their PIN.
        leading: hasPendingSession ? null : widget.leading,
        // When a session is pending, offer a trailing ✕ to cancel it and return
        // to the normal unlock screen.
        // ponytail: ✕ is the only cancel path for a pending session; wire a
        // PopScope here if hardware-back parity is ever requested.
        actions: hasPendingSession
            ? [
                Padding(
                  padding: EdgeInsets.only(
                    right: IrmaTheme.of(context).defaultSpacing,
                  ),
                  child: IrmaCloseButton(
                    onTap: () => _confirmCancelPending(context),
                  ),
                ),
              ]
            : const [],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          KeyedSubtree(
            key: ValueKey(_resetNonce),
            child: YiviPinScreen(
              instruction: subtitle,
              maxPinSize: maxPinSize,
              submitLabel: "pin.unlock",
              onSubmit: enabled ? submit : (_) {},
              enabled: enabled,
              onForgotPin: widget.onForgotPin ?? context.pushResetPinScreen,
              onBiometricUnlock: showBiometric ? _biometricUnlock : null,
              biometricGlyph: showBiometric
                  ? _biometricGlyph(context, biometricType)
                  : null,
              listener: (context, pinState) {
                if (maxPinSize == shortPinSize &&
                    pinState.pin.length == maxPinSize &&
                    enabled) {
                  submit(pinState.toString());
                }
              },
              submitButtonVisibilityListener: (context, _) =>
                  autoSubmitButtonVisibility(maxPinSize),
            ),
          ),
          if (state.authenticateInProgress) const CircularProgressIndicator(),
        ],
      ),
    );
  }
}

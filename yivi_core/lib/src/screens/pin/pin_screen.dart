import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../models/session.dart";
import "../../providers/preferences_provider.dart";
import "../../util/navigation.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/pin_common/format_blocked_for.dart";
import "../../widgets/pin_common/pin_wrong_attempts.dart";
import "../../widgets/pin_common/pin_wrong_blocked.dart";
import "../error/session_error_screen.dart";
import "providers/pin_unlock_provider.dart";
import "yivi_pin_screen.dart";

class PinScreen extends ConsumerStatefulWidget {
  final Function() onAuthenticated;
  final Widget? leading;

  /// Optional override for the "Forgot PIN?" link. The default uses
  /// `context.pushResetPinScreen()`, which goes via GoRouter. Hosts
  /// that mount `PinScreen` outside the GoRouter scope (e.g. the
  /// `LockGate` overlay's local Navigator) should pass a callback
  /// that navigates through the GoRouter instance directly.
  final void Function()? onForgotPin;

  const PinScreen({
    super.key,
    required this.onAuthenticated,
    this.leading,
    this.onForgotPin,
  });

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  // The digit buffer is held here, not built inside the body, so stream
  // emissions (auth state, blocked countdown) no longer recreate it and wipe
  // the dots mid-entry (#508). It survives rebuilds and is only swapped when
  // the user's PIN-length preference actually flips.
  int? _maxPinSize;
  EnterPinStateBloc? _entryBloc;

  EnterPinStateBloc _entryBlocFor(int maxPinSize) {
    if (_entryBloc == null || _maxPinSize != maxPinSize) {
      _entryBloc?.close();
      _maxPinSize = maxPinSize;
      _entryBloc = EnterPinStateBloc(maxPinSize);
    }
    return _entryBloc!;
  }

  @override
  void dispose() {
    _entryBloc?.close();
    super.dispose();
  }

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
    final entryBloc = _entryBlocFor(maxPinSize);

    final blockedFor =
        ref.watch(pinBlockedForProvider).value ?? Duration.zero;
    final enabled =
        blockedFor.inSeconds <= 0 && !state.authenticateInProgress;

    var subtitle = FlutterI18n.translate(context, "pin.subtitle");
    if (blockedFor.inSeconds > 0) {
      final blockedText = FlutterI18n.translate(context, "pin_common.blocked_for");
      subtitle = "$blockedText ${formatBlockedFor(context, blockedFor)}";
    }

    void submit(String pin) => ref.read(pinUnlockProvider.notifier).unlock(pin);

    return YiviPinScaffold(
      appBar: IrmaAppBar(
        titleString: "",
        hasBorder: false,
        leading: widget.leading,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          YiviPinScreen(
            instruction: subtitle,
            maxPinSize: maxPinSize,
            onSubmit: enabled ? submit : (_) {},
            pinBloc: entryBloc,
            enabled: enabled,
            onForgotPin: widget.onForgotPin ?? context.pushResetPinScreen,
            listener: (context, pinState) {
              if (maxPinSize == shortPinSize &&
                  pinState.pin.length == maxPinSize &&
                  enabled) {
                submit(pinState.toString());
              }
            },
          ),
          if (state.authenticateInProgress) const CircularProgressIndicator(),
        ],
      ),
    );
  }
}

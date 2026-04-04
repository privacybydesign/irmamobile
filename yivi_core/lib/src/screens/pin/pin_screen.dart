import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../providers/irma_repository_provider.dart";
import "../../providers/pin_auth_provider.dart";
import "../../util/navigation.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/pin_common/format_blocked_for.dart";
import "../../widgets/pin_common/pin_wrong_attempts.dart";
import "../../widgets/pin_common/pin_wrong_blocked.dart";
import "../error/session_error_screen.dart";
import "yivi_pin_screen.dart";

class PinScreen extends StatelessWidget {
  final Function() onAuthenticated;
  final Widget? leading;

  const PinScreen({super.key, required this.onAuthenticated, this.leading});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        enterPinProvider.overrideWith(() => EnterPinNotifier()),
        pinAuthProvider.overrideWith(() => PinAuthNotifier()),
      ],
      child: _PinScreenBody(onAuthenticated: onAuthenticated, leading: leading),
    );
  }
}

class _PinScreenBody extends ConsumerStatefulWidget {
  final Function() onAuthenticated;
  final Widget? leading;

  const _PinScreenBody({required this.onAuthenticated, this.leading});

  @override
  ConsumerState<_PinScreenBody> createState() => _PinScreenBodyState();
}

class _PinScreenBodyState extends ConsumerState<_PinScreenBody>
    with WidgetsBindingObserver {
  bool _initializedBlockTime = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initializedBlockTime) {
      _initializedBlockTime = true;
      final repo = IrmaRepositoryProvider.of(context);
      repo.getBlockTime().first.then((blockedUntil) {
        if (blockedUntil == null) return;
        ref.read(pinAuthProvider.notifier).setBlocked(blockedUntil);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      FocusScope.of(context).unfocus();
    }
  }

  void _showWrongAttemptsDialog(PinAuthState pinState) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return PinWrongAttemptsDialog(
          attemptsRemaining: pinState.remainingAttempts!,
          onClose: Navigator.of(context).pop,
        );
      },
    );
  }

  void _showBlockedDialog(int secondsBlocked) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => PinWrongBlockedDialog(blocked: secondsBlocked),
    );
  }

  void _goToSessionErrorScreen(PinAuthState pinState) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SessionErrorScreen(
          error: pinState.error,
          onTapClose: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = IrmaRepositoryProvider.of(context).preferences;
    final authState = ref.watch(pinAuthProvider);

    // Listen for auth state changes and handle side effects
    ref.listen(pinAuthProvider, (prev, next) {
      if (next.authenticated) {
        HapticFeedback.mediumImpact();
        widget.onAuthenticated();
      } else if (next.pinInvalid) {
        ref.read(enterPinProvider.notifier).clear();
        HapticFeedback.heavyImpact();
        final secondsBlocked =
            next.blockedUntil?.difference(DateTime.now()).inSeconds ?? 0;
        if (next.remainingAttempts != null && next.remainingAttempts! > 0) {
          _showWrongAttemptsDialog(next);
        } else if (secondsBlocked > 0) {
          _showBlockedDialog(secondsBlocked);
        }
      } else if (next.error != null) {
        ref.read(enterPinProvider.notifier).clear();
        HapticFeedback.heavyImpact();
        _goToSessionErrorScreen(next);
      }
    });

    // Hide pin screen once authenticated
    if (authState.authenticated) {
      return Container();
    }

    return YiviPinScaffold(
      appBar: IrmaAppBar(
        titleString: "",
        hasBorder: false,
        leading: widget.leading,
      ),
      body: StreamBuilder(
        stream: ref.read(pinAuthProvider.notifier).getPinBlockedFor(),
        builder: (BuildContext context, AsyncSnapshot<Duration> blockedFor) {
          var subtitle = FlutterI18n.translate(context, "pin.subtitle");
          if (blockedFor.hasData && (blockedFor.data?.inSeconds ?? 0) > 0) {
            final blockedText = FlutterI18n.translate(
              context,
              "pin_common.blocked_for",
            );
            final blockedForTime = formatBlockedFor(context, blockedFor.data!);
            subtitle = "$blockedText $blockedForTime";
          }

          return StreamBuilder<bool>(
            stream: prefs.getLongPin(),
            builder: (context, snapshot) {
              final maxPinSize = (snapshot.data ?? false)
                  ? longPinSize
                  : shortPinSize;

              final enabled =
                  (blockedFor.data ?? Duration.zero).inSeconds <= 0 &&
                  !authState.authenticateInProgress;

              void submit(String pin) {
                ref.read(pinAuthProvider.notifier).unlock(pin);
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  YiviPinScreen(
                    instruction: subtitle,
                    maxPinSize: maxPinSize,
                    onSubmit: enabled ? submit : (_) {},
                    enabled: enabled,
                    onForgotPin: context.pushResetPinScreen,
                    listener: (context, state) {
                      if (maxPinSize == shortPinSize &&
                          state.pin.length == maxPinSize &&
                          enabled) {
                        submit(state.toString());
                      }
                    },
                  ),
                  if (authState.authenticateInProgress)
                    const CircularProgressIndicator(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

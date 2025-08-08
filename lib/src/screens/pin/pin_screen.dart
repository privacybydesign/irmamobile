import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../providers/irma_repository_provider.dart';
import '../../util/navigation.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/pin_common/format_blocked_for.dart';
import '../../widgets/pin_common/pin_wrong_attempts.dart';
import '../../widgets/pin_common/pin_wrong_blocked.dart';
import '../error/session_error_screen.dart';
import 'bloc/pin_bloc.dart';
import 'bloc/pin_event.dart';
import 'bloc/pin_state.dart';
import 'yivi_pin_screen.dart';

class PinScreen extends StatefulWidget {
  final PinEvent? initialEvent;
  final Function() onAuthenticated;
  final Widget? leading;

  const PinScreen({
    super.key,
    required this.onAuthenticated,
    this.initialEvent,
    this.leading,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> with WidgetsBindingObserver {
  late final PinBloc _pinBloc;

  StreamSubscription? _pinBlocSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // we only want to execute the code below once, so we have to perform this hacky workaround
    // in the future we would need to figure out a better way
    try {
      _pinBloc;
      // return because the init already happened
      return;
    } catch (_) {
      // intentionally kept empty...
    }
    final repo = IrmaRepositoryProvider.of(context);
    _pinBloc = PinBloc(repo);

    if (widget.initialEvent != null) {
      _pinBloc.add(widget.initialEvent!);
    }

    repo.getBlockTime().first.then((blockedUntil) {
      if (blockedUntil == null) {
        return;
      }
      _pinBloc.add(Blocked(blockedUntil));
    });

    _pinBlocSubscription = _pinBloc.stream.listen((pinState) async {
      if (pinState.authenticated) {
        _pinBlocSubscription?.cancel();
      } else if (pinState.pinInvalid) {
        final secondsBlocked = pinState.blockedUntil?.difference(DateTime.now()).inSeconds ?? 0;
        if (pinState.remainingAttempts != null && pinState.remainingAttempts! > 0) {
          _showWrongAttemptsDialog(pinState);
        } else if (secondsBlocked > 0) {
          _showBlockedDialog(secondsBlocked);
        }
      } else if (pinState.error != null) {
        _goToSessionErrorScreen(pinState);
      }
      if (!pinState.authenticated) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }

      // navigate to home when the the user is authenticated
      if (pinState.authenticated) {
        widget.onAuthenticated();
      }
    });
  }

  void _showWrongAttemptsDialog(PinState pinState) {
    if (!mounted) {
      return;
    }
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
    if (!mounted) {
      return;
    }
    showDialog(
      context: context,
      builder: (context) => PinWrongBlockedDialog(
        blocked: secondsBlocked,
      ),
    );
  }

  void _goToSessionErrorScreen(PinState pinState) {
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => SessionErrorScreen(
        error: pinState.error,
        onTapClose: () {
          Navigator.of(context).pop();
        },
      ),
    ));
  }

  @override
  void dispose() {
    _pinBloc.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      FocusScope.of(context).unfocus();
    } else if (state == AppLifecycleState.resumed) {
      if (_pinBloc.state.pinInvalid || _pinBloc.state.authenticateInProgress || _pinBloc.state.error != null) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = IrmaRepositoryProvider.of(context).preferences;
    return BlocBuilder(
      bloc: _pinBloc,
      builder: (context, PinState state) {
        // Hide pin screen once authenticated
        if (state.authenticated == true) {
          return Container();
        }

        return YiviPinScaffold(
          appBar: IrmaAppBar(
            titleString: '',
            hasBorder: false,
            leading: widget.leading,
          ),
          body: StreamBuilder(
            stream: _pinBloc.getPinBlockedFor(),
            builder: (BuildContext context, AsyncSnapshot<Duration> blockedFor) {
              var subtitle = FlutterI18n.translate(context, 'pin.subtitle');
              if (blockedFor.hasData && (blockedFor.data?.inSeconds ?? 0) > 0) {
                final blockedText = FlutterI18n.translate(context, 'pin_common.blocked_for');
                final blockedForTime = formatBlockedFor(context, blockedFor.data!);
                subtitle = '$blockedText $blockedForTime';
              }

              return StreamBuilder<bool>(
                stream: prefs.getLongPin(),
                builder: (context, snapshot) {
                  final maxPinSize = (snapshot.data ?? false) ? longPinSize : shortPinSize;

                  final pinBloc = EnterPinStateBloc(maxPinSize);

                  final enabled = (blockedFor.data ?? Duration.zero).inSeconds <= 0 && !state.authenticateInProgress;

                  void submit(String pin) {
                    _pinBloc.add(
                      Unlock(pin: pin, repo: IrmaRepositoryProvider.of(context)),
                    );
                  }

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      YiviPinScreen(
                        instruction: subtitle,
                        maxPinSize: maxPinSize,
                        onSubmit: enabled ? submit : (_) {},
                        pinBloc: pinBloc,
                        enabled: enabled,
                        onForgotPin: context.pushResetPinScreen,
                        listener: (context, state) {
                          if (maxPinSize == shortPinSize && state.pin.length == maxPinSize && enabled) {
                            submit(state.toString());
                          }
                        },
                      ),
                      if (state.authenticateInProgress) const CircularProgressIndicator(),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

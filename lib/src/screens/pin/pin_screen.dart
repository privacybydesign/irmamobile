import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../data/irma_repository.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_repository_provider.dart';
import '../../widgets/pin_common/format_blocked_for.dart';
import '../../widgets/pin_common/pin_wrong_attempts.dart';
import '../../widgets/pin_common/pin_wrong_blocked.dart';
import '../error/session_error_screen.dart';
import '../reset_pin/reset_pin_screen.dart';

import 'bloc/pin_bloc.dart';
import 'bloc/pin_event.dart';
import 'bloc/pin_state.dart';
import 'yivi_pin_screen.dart';

class PinScreen extends StatefulWidget {
  static const String routeName = '/';
  final PinEvent? initialEvent;

  const PinScreen({Key? key, this.initialEvent}) : super(key: key);

  @override
  _PinScreenState createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> with WidgetsBindingObserver {
  final _pinBloc = PinBloc();
  late StreamSubscription _pinBlocSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);

    if (widget.initialEvent != null) {
      _pinBloc.add(widget.initialEvent);
    }

    IrmaRepository.get().getBlockTime().first.then((blockedUntil) {
      if (blockedUntil != null) {
        _pinBloc.add(Blocked(blockedUntil));
      }
    });

    _pinBlocSubscription = _pinBloc.stream.listen((pinState) async {
      if (pinState.authenticated) {
        _pinBlocSubscription.cancel();
      } else if (pinState.pinInvalid) {
        if (pinState.remainingAttempts != 0) {
          showDialog(
            context: context,
            builder: (context) => PinWrongAttemptsDialog(
              attemptsRemaining: pinState.remainingAttempts,
              onClose: Navigator.of(context).pop,
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => PinWrongBlockedDialog(
              blocked: pinState.blockedUntil.difference(DateTime.now()).inSeconds,
            ),
          );
        }
      } else if (pinState.error != null) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => SessionErrorScreen(
            error: pinState.error,
            onTapClose: () {
              Navigator.of(context).pop();
            },
          ),
        ));
      }
      if (!pinState.authenticated) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    });
  }

  @override
  void dispose() {
    _pinBloc.close();
    WidgetsBinding.instance?.removeObserver(this);
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
    return BlocBuilder<PinBloc, PinState>(
      bloc: _pinBloc,
      builder: (context, state) {
        // Hide pin screen once authenticated
        if (state.authenticated == true) {
          return Container();
        }

        return YiviPinScaffold(
          appBar: const IrmaAppBar(
            noLeading: true,
            title: '',
          ),
          body: StreamBuilder(
            stream: _pinBloc.getPinBlockedFor(),
            builder: (BuildContext context, AsyncSnapshot<Duration> blockedFor) {
              var subtitle = FlutterI18n.translate(context, 'pin.subtitle');
              if (blockedFor.hasData && (blockedFor.data?.inSeconds ?? 0) > 0) {
                final blockedText = FlutterI18n.translate(context, 'pin_common.blocked_for');
                final blockedForTime = formatBlockedFor(context, blockedFor.data);
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
                      Unlock(pin),
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
                        onForgotPin: () => Navigator.of(context).pushNamed(ResetPinScreen.routeName),
                        listener: (context, state) {
                          if (maxPinSize == shortPinSize && state.pin.length == maxPinSize && enabled) {
                            submit(state.toString());
                          }
                        },
                        hideSubmit: shortPinSize == maxPinSize,
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

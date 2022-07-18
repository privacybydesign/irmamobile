import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/screens/error/session_error_screen.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_bloc.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_event.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_state.dart';
import 'package:irmamobile/src/widgets/pin_common/format_blocked_for.dart';
import 'package:irmamobile/src/widgets/pin_common/pin_wrong_attempts.dart';
import 'package:irmamobile/src/widgets/pin_common/pin_wrong_blocked.dart';

import '../../data/irma_preferences.dart';
import '../../widgets/irma_app_bar.dart';
import '../reset_pin/reset_pin_screen.dart';
import 'yivi_pin_screen.dart' as yivi;

class PinScreen extends StatefulWidget {
  static const String routeName = '/';
  final PinEvent initialEvent;

  const PinScreen({Key? key, required this.initialEvent}) : super(key: key);

  @override
  _PinScreenState createState() => _PinScreenState(initialEvent);
}

class _PinScreenState extends State<PinScreen> with WidgetsBindingObserver {
  final _pinBloc = PinBloc();
  final _pinVisibilityBloc = yivi.PinVisibilityBloc();

  late StreamSubscription _pinBlocSubscription;

  _PinScreenState(PinEvent? initialEvent) {
    if (initialEvent != null) {
      _pinBloc.add(initialEvent);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);

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
              onClose: () {
                Navigator.of(context).pop();
                // _focusNode.requestFocus(); // redo
              },
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
      } else {}
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
    return BlocBuilder<PinBloc, PinState>(
      bloc: _pinBloc,
      builder: (context, state) {
        // Hide pin screen once authenticated
        if (state.authenticated == true) {
          return Container();
        }

        return yivi.YiviPinScaffold(
          appBar: IrmaAppBar(
            titleTranslationKey: "pin.title",
          ),
          body: StreamBuilder(
            stream: _pinBloc.getPinBlockedFor(),
            builder: (BuildContext context, AsyncSnapshot<Duration> blockedFor) {
              var subtitle = FlutterI18n.translate(context, 'pin.subtitle');
              if (blockedFor.hasData && (blockedFor.data?.inSeconds ?? 0) > 0) {
                final blockedText = '${FlutterI18n.translate(context, "pin_common.blocked_for")}';
                final blockedForTime = formatBlockedFor(context, blockedFor.data);
                subtitle = '$blockedText $blockedForTime';
              }

              return StreamBuilder(
                stream: IrmaPreferences.get().getLongPin(),
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  final maxPinSize = (snapshot.hasData && snapshot.data!) ? yivi.longPinSize : yivi.shortPinSize;
                  final pinBloc = yivi.EnterPinStateBloc(maxPinSize);

                  final enabled = (blockedFor.data ?? Duration.zero).inSeconds <= 0 && !state.authenticateInProgress;

                  void onSubmit() {
                    _pinBloc.add(
                      Unlock(pinBloc.state.pin.join()),
                    );
                  }

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      yivi.YiviPinScreen(
                        instruction: subtitle,
                        maxPinSize: maxPinSize,
                        onSubmit: enabled ? onSubmit : () {},
                        pinBloc: pinBloc,
                        pinVisibilityBloc: _pinVisibilityBloc,
                        enabled: enabled,
                        onForgotPin: () => Navigator.of(context).pushNamed(ResetPinScreen.routeName),
                        listener: (context, state) {
                          if (maxPinSize == yivi.shortPinSize && state.pin.length == maxPinSize && enabled) {
                            onSubmit();
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/screens/error/session_error_screen.dart';
import 'package:irmamobile/src/screens/home/home_screen.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_bloc.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_state.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/loading_indicator.dart';
import 'package:irmamobile/src/widgets/pin_common/pin_wrong_attempts.dart';

import '../../data/irma_preferences.dart';
import '../../theme/theme.dart';
import '../reset_pin/reset_pin_screen.dart';
import 'bloc/pin_event.dart';
import 'yivi_pin_screen.dart' as yivi;

class SessionPinScreen extends StatefulWidget {
  final int sessionID;
  final String title;

  const SessionPinScreen({Key? key, required this.sessionID, required this.title}) : super(key: key);

  @override
  _SessionPinScreenState createState() => _SessionPinScreenState();
}

class _SessionPinScreenState extends State<SessionPinScreen> with WidgetsBindingObserver {
  final _repo = IrmaRepository.get();
  final _pinBloc = PinBloc();
  final _focusNode = FocusNode();
  final _navigatorKey = GlobalKey();

  late final StreamSubscription _pinBlocSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);

    // Listener uses context from _navigatorKey, so we have to wait until the navigator is built.
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _pinBlocSubscription = _pinBloc.stream.listen((pinState) async {
        if (pinState.pinInvalid) {
          _handleInvalidPin(pinState);
        } else {
          if (pinState.error != null) {
            _handleError(pinState);
          }
          FocusScope.of(_navigatorKey.currentContext!).requestFocus(_focusNode);
        }
      });
    });
  }

  @override
  void dispose() {
    _pinBlocSubscription.cancel();
    _focusNode.dispose();
    _pinBloc.close();
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  void _cancel() {
    _repo.dispatch(
      RespondPinEvent(sessionID: widget.sessionID, proceed: false),
      isBridgedEvent: true,
    );
  }

  void _handleInvalidPin(PinState state) {
    if (state.remainingAttempts != 0) {
      showDialog(
        context: _navigatorKey.currentContext!,
        useRootNavigator: false,
        builder: (BuildContext context) => PinWrongAttemptsDialog(
          attemptsRemaining: state.remainingAttempts,
          onClose: () {
            Navigator.of(_navigatorKey.currentContext!).pop();
            _focusNode.requestFocus();
          },
        ),
      );
    } else {
      Navigator.of(context, rootNavigator: true).popUntil(ModalRoute.withName(HomeScreen.routeName));
      _repo.lock(unblockTime: state.blockedUntil);
    }
  }

  void _handleError(PinState state) {
    Navigator.of(_navigatorKey.currentContext!).push(MaterialPageRoute(
      builder: (context) => SessionErrorScreen(
        error: state.error,
        onTapClose: () {
          Navigator.of(_navigatorKey.currentContext!).pop();
          _focusNode.requestFocus();
        },
      ),
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      FocusScope.of(_navigatorKey.currentContext!).unfocus();
    } else if (state == AppLifecycleState.resumed) {
      final pinState = _pinBloc.state;
      if (pinState.pinInvalid || pinState.authenticateInProgress || pinState.error != null) return;
      Future.delayed(const Duration(milliseconds: 100), () {
        // Screen might have popped during the delay, so check whether currentContext exists first
        if (_navigatorKey.currentContext != null) {
          FocusScope.of(_navigatorKey.currentContext!).requestFocus(_focusNode);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Wait on irmago response before closing, calling widget expects a result
        return _pinBloc.stream
            .firstWhere(
          (state) => !state.authenticateInProgress,
        )
            .then((state) {
          if (!state.authenticated) _cancel();
          return false;
        });
      },
      // Wrap component in custom navigator in order to manage the invalid pin popup and the
      // error screen as widget ourselves, such that popping this widget from the root navigator will
      // include popping the invalid pin popup and error screen too.
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => BlocBuilder<PinBloc, PinState>(
            bloc: _pinBloc,
            builder: (context, state) {
              if (state.authenticated) {
                // Wait until parent screen pops this widget.
                return Scaffold(
                  appBar: _buildAppBar(),
                  body: LoadingIndicator(),
                );
              }

              return Scaffold(
                appBar: _buildAppBar(),
                body: StreamBuilder(
                  stream: _pinBloc.getPinBlockedFor(),
                  builder: (BuildContext context, AsyncSnapshot<Duration> blockedFor) {
                    return StreamBuilder(
                      stream: IrmaPreferences.get().getLongPin(),
                      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                        final maxPinSize = (snapshot.hasData && snapshot.data!) ? yivi.longPinSize : yivi.shortPinSize;
                        final pinBloc = yivi.PinStateBloc(maxPinSize);

                        final enabled =
                            (blockedFor.data ?? Duration.zero).inSeconds <= 0 && !state.authenticateInProgress;

                        void onSubmit() {
                          if (!enabled) return;
                          _pinBloc.add(
                            SessionPin(widget.sessionID, pinBloc.state.pin.join()),
                          );
                        }

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            yivi.YiviPinScreen(
                              instructionKey: 'session_pin.subtitle',
                              maxPinSize: maxPinSize,
                              onSubmit: onSubmit,
                              pinBloc: pinBloc,
                              pinVisibilityBloc: yivi.PinVisibilityBloc(),
                              enabled: enabled,
                              onForgotPin: () => Navigator.of(context).pushNamed(ResetPinScreen.routeName),
                              listener: (context, state) {
                                if (maxPinSize == yivi.shortPinSize &&
                                    state.attributes.contains(yivi.SecurePinAttribute.goodEnough)) {
                                  onSubmit();
                                }
                              },
                            ),
                            if (state.authenticateInProgress)
                              Padding(
                                  padding: EdgeInsets.all(IrmaTheme.of(context).defaultSpacing),
                                  child: const CircularProgressIndicator()),
                          ],
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return IrmaAppBar(
      titleTranslationKey: widget.title,

      // Parent widget is responsible for popping this widget, so do a leadingAction instead of a leadingCancel.
      leadingAction: () {
        _cancel();
      },
    );
  }
}

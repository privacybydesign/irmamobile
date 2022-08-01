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

import '../../theme/theme.dart';
import '../reset_pin/reset_pin_screen.dart';
import 'bloc/pin_event.dart';
import 'yivi_pin_screen.dart';

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
        }
      });
    });
  }

  @override
  void dispose() {
    _pinBlocSubscription.cancel();
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
    final navigatorContext = _navigatorKey.currentContext;
    if (state.remainingAttempts != 0 && navigatorContext != null) {
      showDialog(
        context: navigatorContext,
        useRootNavigator: false,
        builder: (BuildContext context) => PinWrongAttemptsDialog(
          attemptsRemaining: state.remainingAttempts,
          onClose: () {
            Navigator.of(navigatorContext).pop();
          },
        ),
      );
    } else {
      Navigator.of(context, rootNavigator: true).popUntil(ModalRoute.withName(HomeScreen.routeName));
      _repo.lock(unblockTime: state.blockedUntil);
    }
  }

  void _handleError(PinState state) {
    final navigatorContext = _navigatorKey.currentContext;
    if (navigatorContext != null) {
      Navigator.of(navigatorContext).push(MaterialPageRoute(
        builder: (context) => SessionErrorScreen(
          error: state.error,
          onTapClose: () {
            Navigator.of(navigatorContext).pop();
          },
        ),
      ));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final pinState = _pinBloc.state;
      if (pinState.pinInvalid || pinState.authenticateInProgress || pinState.error != null) return;
    }
  }

  // Parent widget is responsible for popping this widget, so do a leadingAction instead of a leadingCancel.
  PreferredSizeWidget _scaffoldTitle() => IrmaAppBar(leadingAction: _cancel, title: widget.title);

  void _submit(bool enabled, String pin) {
    if (!enabled) return;
    _pinBloc.add(
      SessionPin(widget.sessionID, pin),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = _repo.preferences;
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
                  appBar: _scaffoldTitle(),
                  body: LoadingIndicator(),
                );
              }

              return YiviPinScaffold(
                appBar: _scaffoldTitle(),
                body: StreamBuilder(
                  stream: _pinBloc.getPinBlockedFor(),
                  builder: (BuildContext context, AsyncSnapshot<Duration> blockedFor) {
                    return StreamBuilder<bool>(
                      stream: prefs.getLongPin(),
                      builder: (context, snapshot) {
                        final maxPinSize = (snapshot.data ?? false) ? longPinSize : shortPinSize;
                        final pinBloc = EnterPinStateBloc(maxPinSize);

                        final enabled =
                            (blockedFor.data ?? Duration.zero).inSeconds <= 0 && !state.authenticateInProgress;

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            YiviPinScreen(
                              instructionKey: 'session_pin.subtitle',
                              maxPinSize: maxPinSize,
                              onSubmit: (p) => _submit(enabled, p),
                              pinBloc: pinBloc,
                              enabled: enabled,
                              onForgotPin: () => Navigator.of(context).pushNamed(ResetPinScreen.routeName),
                              listener: (context, state) {
                                if (maxPinSize == shortPinSize && state.pin.length == maxPinSize) {
                                  _submit(enabled, state.toString());
                                }
                              },
                              hideSubmit: shortPinSize == maxPinSize,
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
}

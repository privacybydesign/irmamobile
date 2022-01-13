// This code is not null safe yet.
// @dart=2.11

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/screens/error/session_error_screen.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_bloc.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_event.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_state.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/loading_indicator.dart';
import 'package:irmamobile/src/widgets/pin_common/pin_wrong_attempts.dart';
import 'package:irmamobile/src/widgets/pin_field.dart';

import '../../data/irma_preferences.dart';

class SessionPinScreen extends StatefulWidget {
  final int sessionID;
  final String title;

  const SessionPinScreen({Key key, @required this.sessionID, @required this.title}) : super(key: key);

  @override
  _SessionPinScreenState createState() => _SessionPinScreenState();
}

class _SessionPinScreenState extends State<SessionPinScreen> with WidgetsBindingObserver {
  final _repo = IrmaRepository.get();
  final _pinBloc = PinBloc();
  final _focusNode = FocusNode();
  final _navigatorKey = GlobalKey();

  StreamSubscription _pinBlocSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listener uses context from _navigatorKey, so we have to wait until the navigator is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinBlocSubscription = _pinBloc.stream.listen((pinState) async {
        if (pinState.pinInvalid) {
          _handleInvalidPin(pinState);
        } else {
          if (pinState.error != null) {
            _handleError(pinState);
          }
          FocusScope.of(_navigatorKey.currentContext).requestFocus(_focusNode);
        }
      });
    });
  }

  @override
  void dispose() {
    _pinBlocSubscription?.cancel();
    _focusNode.dispose();
    _pinBloc.close();
    WidgetsBinding.instance.removeObserver(this);
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
        context: _navigatorKey.currentContext,
        useRootNavigator: false,
        builder: (BuildContext context) => PinWrongAttemptsDialog(
          attemptsRemaining: state.remainingAttempts,
          onClose: () {
            Navigator.of(_navigatorKey.currentContext).pop();
            _focusNode.requestFocus();
          },
        ),
      );
    } else {
      Navigator.of(context, rootNavigator: true).popUntil(ModalRoute.withName(WalletScreen.routeName));
      _repo.lock(unblockTime: state.blockedUntil);
    }
  }

  void _handleError(PinState state) {
    Navigator.of(_navigatorKey.currentContext).push(MaterialPageRoute(
      builder: (context) => SessionErrorScreen(
        error: state.error,
        onTapClose: () {
          Navigator.of(_navigatorKey.currentContext).pop();
          _focusNode.requestFocus();
        },
      ),
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      FocusScope.of(_navigatorKey.currentContext).unfocus();
    } else if (state == AppLifecycleState.resumed) {
      final pinState = _pinBloc.state;
      if (pinState.pinInvalid || pinState.authenticateInProgress || pinState.error != null) return;
      Future.delayed(const Duration(milliseconds: 100), () {
        // Screen might have popped during the delay, so check whether currentContext exists first
        if (_navigatorKey.currentContext != null) {
          FocusScope.of(_navigatorKey.currentContext).requestFocus(_focusNode);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Wait on irmago response before closing, calling widget expects a result
        return _pinBloc.stream.firstWhere((state) => !state.authenticateInProgress, orElse: () => null).then((state) {
          if (state != null && !state.authenticated) _cancel();
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
                body: SafeArea(
                  minimum: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          height: IrmaTheme.of(context).largeSpacing,
                        ),
                        Text(
                          FlutterI18n.translate(context, "session_pin.subtitle"),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: IrmaTheme.of(context).defaultSpacing,
                        ),
                        StreamBuilder(
                          stream: IrmaPreferences.get().getLongPin(),
                          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) => PinField(
                            focusNode: _focusNode,
                            longPin: snapshot.hasData && snapshot.data,
                            enabled: !state.authenticateInProgress,
                            onSubmit: (pin) {
                              FocusScope.of(context).requestFocus();
                              _pinBloc.add(
                                SessionPin(widget.sessionID, pin),
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          height: IrmaTheme.of(context).defaultSpacing,
                        ),
                        Icon(
                          IrmaIcons.duration,
                          color: IrmaTheme.of(context).primaryDark,
                          size: 32,
                        ),
                        SizedBox(
                          height: IrmaTheme.of(context).defaultSpacing,
                        ),
                        Text(
                          FlutterI18n.translate(context, "session_pin.explanation"),
                          textAlign: TextAlign.center,
                        ),
                        if (state.authenticateInProgress)
                          Padding(
                              padding: EdgeInsets.all(IrmaTheme.of(context).defaultSpacing),
                              child: const CircularProgressIndicator()),
                      ],
                    ),
                  ),
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
      title: Text(
        widget.title,
      ),
      // Parent widget is responsible for popping this widget, so do a leadingAction instead of a leadingCancel.
      leadingAction: () {
        _cancel();
      },
    );
  }
}

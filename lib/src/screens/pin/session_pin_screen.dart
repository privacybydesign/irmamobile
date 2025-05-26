import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/irma_repository.dart';
import '../../models/session_events.dart';
import '../../providers/irma_repository_provider.dart';
import '../../theme/theme.dart';
import '../../util/navigation.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/pin_common/pin_wrong_attempts.dart';
import '../error/session_error_screen.dart';
import 'bloc/pin_bloc.dart';
import 'bloc/pin_event.dart';
import 'bloc/pin_state.dart';
import 'yivi_pin_screen.dart';

class SessionPinScreen extends StatefulWidget {
  final int sessionID;
  final String title;

  const SessionPinScreen({super.key, required this.sessionID, required this.title});

  @override
  State<SessionPinScreen> createState() => _SessionPinScreenState();
}

class _SessionPinScreenState extends State<SessionPinScreen> with WidgetsBindingObserver {
  late final IrmaRepository _repo;
  late final PinBloc _pinBloc;
  final _navigatorKey = GlobalKey();

  StreamSubscription? _pinBlocSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listener uses context from _navigatorKey, so we have to wait until the navigator is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinBlocSubscription = _pinBloc.stream.listen((pinState) async {
        if (pinState.pinInvalid) {
          _handleInvalidPin(pinState);
          HapticFeedback.heavyImpact();
        } else if (pinState.error != null) {
          _handleError(pinState);
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.mediumImpact();
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // only init _repo once...
    try {
      _repo;
    } catch (_) {
      _repo = IrmaRepositoryProvider.of(context);
      _pinBloc = PinBloc(_repo);
    }
  }

  @override
  void dispose() {
    _pinBlocSubscription?.cancel();
    _pinBloc.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _cancel() {
    _repo.bridgedDispatch(RespondPinEvent(sessionID: widget.sessionID, proceed: false));
  }

  void _handleInvalidPin(PinState state) {
    final navigatorContext = _navigatorKey.currentContext;
    if (navigatorContext != null && state.remainingAttempts != null && state.remainingAttempts! > 0) {
      showDialog(
        context: navigatorContext,
        useRootNavigator: false,
        builder: (BuildContext context) => PinWrongAttemptsDialog(
          attemptsRemaining: state.remainingAttempts!,
          onClose: Navigator.of(navigatorContext).pop,
        ),
      );
    } else {
      context.goHomeScreen();
      _repo.lock(unblockTime: state.blockedUntil);
    }
  }

  void _handleError(PinState state) {
    final navigatorContext = _navigatorKey.currentContext;
    if (navigatorContext != null) {
      Navigator.of(navigatorContext).push(MaterialPageRoute(
        builder: (context) => SessionErrorScreen(
          error: state.error,
          onTapClose: Navigator.of(navigatorContext).pop,
        ),
      ));
    }
  }

  // Parent widget is responsible for popping this widget, so do a leadingAction instead of a leadingCancel.
  PreferredSizeWidget _scaffoldTitle() {
    return IrmaAppBar(
      leading: YiviBackButton(onTap: _cancel),
      title: widget.title,
    );
  }

  void _submit(bool enabled, String pin) {
    if (!enabled) return;
    _pinBloc.add(
      SessionPin(sessionID: widget.sessionID, pin: pin, repo: _repo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = _repo.preferences;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, popResult) async {
        // Wait on irmago response before closing, calling widget expects a result
        final pinState = await _pinBloc.stream.firstWhere((state) => !state.authenticateInProgress);
        if (!pinState.authenticated) {
          _cancel();
        }
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
                  body: Center(child: LoadingIndicator()),
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
                              onForgotPin: context.pushResetPinScreen,
                              listener: (context, state) {
                                if (maxPinSize == shortPinSize && state.pin.length == maxPinSize) {
                                  _submit(enabled, state.toString());
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
}

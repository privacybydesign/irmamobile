import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../data/irma_repository.dart";
import "../../models/session_events.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/pin_auth_provider.dart";
import "../../theme/theme.dart";
import "../../util/navigation.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/loading_indicator.dart";
import "../../widgets/pin_common/pin_wrong_attempts.dart";
import "../error/session_error_screen.dart";
import "yivi_pin_screen.dart";

class SessionPinScreen extends StatelessWidget {
  final int sessionID;
  final String title;

  const SessionPinScreen({
    super.key,
    required this.sessionID,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        enterPinProvider.overrideWith(() => EnterPinNotifier()),
        pinAuthProvider.overrideWith(() => PinAuthNotifier()),
      ],
      child: _SessionPinScreenBody(sessionID: sessionID, title: title),
    );
  }
}

class _SessionPinScreenBody extends ConsumerStatefulWidget {
  final int sessionID;
  final String title;

  const _SessionPinScreenBody({required this.sessionID, required this.title});

  @override
  ConsumerState<_SessionPinScreenBody> createState() =>
      _SessionPinScreenBodyState();
}

class _SessionPinScreenBodyState extends ConsumerState<_SessionPinScreenBody>
    with WidgetsBindingObserver {
  late final IrmaRepository _repo;
  final _navigatorKey = GlobalKey();
  bool _repoInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_repoInitialized) {
      _repoInitialized = true;
      _repo = IrmaRepositoryProvider.of(context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _cancel() {
    _repo.bridgedDispatch(
      RespondPinEvent(sessionID: widget.sessionID, proceed: false),
    );
  }

  void _handleInvalidPin(PinAuthState state) {
    final navigatorContext = _navigatorKey.currentContext;
    if (navigatorContext != null &&
        state.remainingAttempts != null &&
        state.remainingAttempts! > 0) {
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

  void _handleError(PinAuthState state) {
    final navigatorContext = _navigatorKey.currentContext;
    if (navigatorContext != null) {
      Navigator.of(navigatorContext).push(
        MaterialPageRoute(
          builder: (context) => SessionErrorScreen(
            error: state.error,
            onTapClose: Navigator.of(navigatorContext).pop,
          ),
        ),
      );
    }
  }

  PreferredSizeWidget _scaffoldTitle() {
    return IrmaAppBar(
      leading: YiviBackButton(onTap: _cancel),
      titleString: widget.title,
    );
  }

  void _submit(bool enabled, String pin) {
    if (!enabled) return;
    ref
        .read(pinAuthProvider.notifier)
        .authenticateSession(widget.sessionID, pin);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = _repo.preferences;
    final authState = ref.watch(pinAuthProvider);

    // Listen for auth state changes and handle side effects
    ref.listen(pinAuthProvider, (prev, next) {
      if (next.pinInvalid) {
        ref.read(enterPinProvider.notifier).clear();
        _handleInvalidPin(next);
        HapticFeedback.heavyImpact();
      } else if (next.error != null) {
        ref.read(enterPinProvider.notifier).clear();
        _handleError(next);
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, popResult) async {
        if (!authState.authenticated) {
          _cancel();
        }
      },
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) {
            if (authState.authenticated) {
              return Scaffold(
                appBar: _scaffoldTitle(),
                body: Center(child: LoadingIndicator()),
              );
            }

            return YiviPinScaffold(
              appBar: _scaffoldTitle(),
              body: StreamBuilder(
                stream: ref.read(pinAuthProvider.notifier).getPinBlockedFor(),
                builder:
                    (BuildContext context, AsyncSnapshot<Duration> blockedFor) {
                      return StreamBuilder<bool>(
                        stream: prefs.getLongPin(),
                        builder: (context, snapshot) {
                          final maxPinSize = (snapshot.data ?? false)
                              ? longPinSize
                              : shortPinSize;

                          final enabled =
                              (blockedFor.data ?? Duration.zero).inSeconds <=
                                  0 &&
                              !authState.authenticateInProgress;

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              YiviPinScreen(
                                instructionKey: "session_pin.subtitle",
                                maxPinSize: maxPinSize,
                                onSubmit: (p) => _submit(enabled, p),
                                enabled: enabled,
                                onForgotPin: context.pushResetPinScreen,
                                listener: (context, state) {
                                  if (maxPinSize == shortPinSize &&
                                      state.pin.length == maxPinSize) {
                                    _submit(enabled, state.toString());
                                  }
                                },
                              ),
                              if (authState.authenticateInProgress)
                                Padding(
                                  padding: EdgeInsets.all(
                                    IrmaTheme.of(context).defaultSpacing,
                                  ),
                                  child: const CircularProgressIndicator(),
                                ),
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
    );
  }
}

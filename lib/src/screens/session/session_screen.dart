import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../data/irma_repository.dart';
import '../../models/native_events.dart';
import '../../models/return_url.dart';
import '../../models/session.dart';
import '../../models/session_events.dart';
import '../../models/session_state.dart';
import '../../sentry/sentry.dart';
import '../../util/combine.dart';
import '../../util/navigation.dart';
import '../../widgets/loading_indicator.dart';
import '../error/session_error_screen.dart';
import '../pin/session_pin_screen.dart';
import 'call_info_screen.dart';
import 'disclosure/disclosure_permission.dart';
import 'session.dart';
import 'widgets/arrow_back_screen.dart';
import 'widgets/disclosure_feedback_screen.dart';
import 'widgets/issuance_permission.dart';
import 'widgets/issuance_success_screen.dart';
import 'widgets/pairing_required.dart';
import 'widgets/session_scaffold.dart';

class SessionScreen extends StatefulWidget {
  static const String routeName = '/session';

  final SessionScreenArguments arguments;

  const SessionScreen({required this.arguments}) : super();

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final IrmaRepository _repo = IrmaRepository.get();
  final ValueNotifier<bool> _displayArrowBack = ValueNotifier<bool>(false);
  late Stream<SessionState> _sessionStateStream;

  @override
  void initState() {
    super.initState();
    _sessionStateStream = _repo.getSessionState(widget.arguments.sessionID);
  }

  @override
  void dispose() {
    _sessionStateStream.first.then((session) {
      if (!session.isFinished) {
        _dismissSession();
      }
      if (session.isIssuanceSession) {
        final issuedCredentialTypeIds = session.issuedCredentials?.map((e) => e.credentialType.fullId) ?? [];
        _repo.removeLaunchedCredentials(issuedCredentialTypeIds);
      }
    });
    super.dispose();
  }

  String _getAppBarTitle(bool isIssuance) {
    return isIssuance ? 'issuance.title' : 'disclosure.title';
  }

  void _dispatchSessionEvent(SessionEvent event, {bool isBridgedEvent = true}) =>
      _repo.dispatch(event, isBridgedEvent: isBridgedEvent);

  void _dismissSession() {
    _dispatchSessionEvent(DismissSessionEvent(sessionID: widget.arguments.sessionID));
  }

  void _giveIssuancePermission(SessionState session) {
    _dispatchSessionEvent(RespondPermissionEvent(
      sessionID: widget.arguments.sessionID,
      proceed: true,
      disclosureChoices: session.disclosureChoices ?? [],
    ));
  }

  void _popToUnderlyingOrHome() {
    if (widget.arguments.wizardActive) {
      popToWizard(context);
    } else if (widget.arguments.hasUnderlyingSession) {
      Navigator.of(context).pop();
    } else {
      popToHome(context);
    }
  }

  /// Opens the given clientReturnUrl in the in-app browser, if the url is suitable for the in-app browser, otherwise
  /// the URL is opened externally. In case the URL cannot be opened, a FailureSessionEvent is dispatched. In case
  /// of a silentFailure, only an error report is made for Sentry.
  Future<bool> _openClientReturnUrl(
    ReturnURL clientReturnUrl, {
    bool alwaysOpenExternally = false,
    bool silentFailure = false,
  }) async {
    try {
      if (clientReturnUrl.isInApp && !alwaysOpenExternally) {
        await _repo.openURLinAppBrowser(clientReturnUrl.toString());
      } else {
        await _repo.openURLExternally(clientReturnUrl.toString());
      }
      return true;
    } catch (e, stackTrace) {
      if (silentFailure) {
        reportError(e, stackTrace);
      } else {
        _dispatchSessionEvent(
          FailureSessionEvent(
            sessionID: widget.arguments.sessionID,
            error: SessionError(
              errorType: 'clientReturnUrl',
              info: 'the clientReturnUrl could not be handled',
              wrappedError: e.toString(),
            ),
          ),
          isBridgedEvent: false,
        );
      }
      return false;
    }
  }

  Widget _buildDismissed(SessionState session) {
    WidgetsBinding.instance?.addPostFrameCallback((_) => Navigator.of(context).pop());
    return _buildLoadingScreen(session.isIssuanceSession);
  }

  Widget _buildFinishedContinueSecondDevice(SessionState session) {
    if (session.isIssuanceSession) {
      final issuedCredentialTypeIds = session.issuedCredentials?.map((e) => e.credentialType.fullId) ?? [];
      _repo.removeLaunchedCredentials(issuedCredentialTypeIds);

      if (session.status == SessionStatus.success) {
        return const IssuanceSuccessScreen(
          onDismiss: popToHome,
        );
      } else {
        return _buildDismissed(session);
      }
    }

    if (session.dismissed) return _buildDismissed(session);

    final serverName = session.serverName.name.translate(FlutterI18n.currentLocale(context)!.languageCode);
    final feedbackType =
        session.status == SessionStatus.success ? DisclosureFeedbackType.success : DisclosureFeedbackType.canceled;
    return DisclosureFeedbackScreen(
      feedbackType: feedbackType,
      otherParty: serverName,
      onDismiss: popToHome,
    );
  }

  Widget _buildFinishedReturnPhoneNumber(SessionState session) {
    final serverName = session.serverName.name.translate(FlutterI18n.currentLocale(context)!.languageCode);

    // Navigate to call info screen when session succeeded.
    // Otherwise cancel the regular way for the particular session type.
    if (session.status == SessionStatus.success) {
      return CallInfoScreen(
        otherParty: serverName,
        onContinue: () async {
          try {
            await _repo.openURLExternally(session.clientReturnURL.toString());
            if (mounted) popToHome(context);
          } catch (e) {
            _dispatchSessionEvent(
              FailureSessionEvent(
                sessionID: widget.arguments.sessionID,
                error: SessionError(
                  errorType: 'clientReturnUrl',
                  info: 'the phone number in the clientReturnUrl could not be handled',
                  wrappedError: e.toString(),
                ),
              ),
              isBridgedEvent: false,
            );
          }
        },
        onCancel: () => popToHome(context),
      );
    } else if (session.isIssuanceSession) {
      WidgetsBinding.instance?.addPostFrameCallback((_) => popToHome(context));
      return _buildLoadingScreen(true);
    } else if (session.dismissed) {
      return _buildDismissed(session);
    } else {
      return DisclosureFeedbackScreen(
        feedbackType: DisclosureFeedbackType.canceled,
        otherParty: serverName,
        onDismiss: popToHome,
      );
    }
  }

  Widget _buildFinished(SessionState session) {
    // In case of issuance during disclosure, another session is open in a screen lower in the stack.
    // Ignore clientReturnUrl in this case (issuance) and pop immediately.
    if (session.isIssuanceSession && widget.arguments.hasUnderlyingSession) {
      WidgetsBinding.instance?.addPostFrameCallback((_) => Navigator.of(context).pop());
      return _buildLoadingScreen(true);
    }

    if (session.clientReturnURL?.isPhoneNumber ?? false) {
      return _buildFinishedReturnPhoneNumber(session);
    }

    if (session.continueOnSecondDevice ||
        session.didIssuePreviouslyLaunchedCredential &&
            // Check to rule out the combined issuance and disclosure sessions
            (session.disclosuresCandidates == null || session.disclosuresCandidates!.isEmpty)) {
      return _buildFinishedContinueSecondDevice(session);
    }

    final issuedWizardCred = widget.arguments.wizardActive &&
        widget.arguments.wizardCred != null &&
        (session.issuedCredentials?.map((c) => c.info.fullId).contains(widget.arguments.wizardCred) ?? false);

    // It concerns a mobile session.
    if (session.clientReturnURL != null && !issuedWizardCred) {
      // If there is a return URL, navigate to it when we're done.
      WidgetsBinding.instance?.addPostFrameCallback((_) async {
        // When being in a disclosure, we can continue to underlying sessions in this case;
        // hasUnderlyingSession during issuance is handled at the beginning of _buildFinished, so
        // we don't have to explicitly exclude issuance here.
        if (session.clientReturnURL!.isInApp) {
          _popToUnderlyingOrHome();
          await _openClientReturnUrl(session.clientReturnURL!);
        } else {
          final hasOpened = await _openClientReturnUrl(session.clientReturnURL!);
          if (!hasOpened || !mounted) return;
          _popToUnderlyingOrHome();
        }
      });
    } else if (widget.arguments.wizardActive || session.didIssuePreviouslyLaunchedCredential) {
      // If the wizard is active or this concerns a combined session, pop accordingly.
      WidgetsBinding.instance?.addPostFrameCallback(
        (_) => widget.arguments.wizardActive ? popToWizard(context) : Navigator.of(context).pop(),
      );
    } else if (widget.arguments.hasUnderlyingSession) {
      // In case of a disclosure having an underlying session we only continue to underlying session
      // if it is a mobile session and there was no clientReturnUrl.
      WidgetsBinding.instance?.addPostFrameCallback((_) => Navigator.of(context).pop());
    } else if (Platform.isIOS) {
      // On iOS, show a screen to press the return arrow in the top-left corner.
      return ArrowBack(
        success: session.status == SessionStatus.success,
        amountIssued: session.issuedCredentials?.length ?? 0,
      );
    } else {
      // On Android just background the app to let the user return to the previous activity
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        _repo.bridgedDispatch(AndroidSendToBackgroundEvent());
        popToHome(context);
      });
    }
    return _buildLoadingScreen(session.isIssuanceSession);
  }

  Widget _buildErrorScreen(SessionState session) => ValueListenableBuilder(
        valueListenable: _displayArrowBack,
        builder: (BuildContext context, bool displayArrowBack, Widget? child) {
          if (displayArrowBack) {
            return const ArrowBack(
              amountIssued: 0,
            );
          }
          return child ?? Container();
        },
        child: SessionErrorScreen(
          error: session.error,
          onTapClose: () async {
            if (widget.arguments.wizardActive) {
              popToWizard(context);
            } else if (session.continueOnSecondDevice) {
              popToHome(context);
            } else if (session.clientReturnURL != null && !session.clientReturnURL!.isPhoneNumber) {
              // If the error was caused by the client return url itself, we should not open it again.
              if (session.error?.errorType != 'clientReturnUrl') {
                // For now we do a silentFailure if an error occurs, to prevent two subsequent error screens.
                await _openClientReturnUrl(session.clientReturnURL!, alwaysOpenExternally: true, silentFailure: true);
              }
              popToHome(context);
            } else {
              if (Platform.isIOS) {
                _displayArrowBack.value = true;
              } else {
                _repo.bridgedDispatch(AndroidSendToBackgroundEvent());
                popToHome(context);
              }
            }
          },
        ),
      );

  Widget _buildLoadingScreen(bool isIssuance) => SessionScaffold(
        body: Center(
          child: LoadingIndicator(),
        ),
        onDismiss: () => _dismissSession(),
        appBarTitle: _getAppBarTitle(isIssuance),
      );

  @override
  Widget build(BuildContext context) => StreamBuilder(
      // This screen is designed to only build when dealing with a session status change. Therefore
      // we filter the stream to only include distinct statuses. State changes within a session status
      // should be handled by stateful child widgets of this screen. We make an exception for the
      // requestDisclosurePermission status such that the disclosure candidates are being refreshed in
      // an issuance-in-disclosure session.
      stream: combine2(
        _repo.getLocked(),
        _sessionStateStream.distinct(
            (prev, curr) => prev.status == curr.status && curr.status != SessionStatus.requestDisclosurePermission),
      ),
      builder: (BuildContext context, AsyncSnapshot<CombinedState2<bool, SessionState>> snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingScreen(widget.arguments.sessionType == 'issuing');
        }

        // Prevent stealing focus from pin screen in case app is locked
        final locked = snapshot.data!.a;
        Navigator.of(context).focusScopeNode.canRequestFocus = !locked;

        final session = snapshot.data!.b;

        switch (session.status) {
          case SessionStatus.pairing:
            return PairingRequired(
              pairingCode: session.pairingCode ?? '',
              onDismiss: () => _dismissSession(),
            );
          case SessionStatus.requestDisclosurePermission:
            if (session.canBeFinished ?? false) {
              return DisclosurePermission(
                sessionId: session.sessionID,
                requestor: session.serverName,
                returnURL: session.clientReturnURL,
                repo: _repo,
              );
            } else {
              final serverName = session.serverName.name.translate(FlutterI18n.currentLocale(context)!.languageCode);
              return DisclosureFeedbackScreen(
                feedbackType: DisclosureFeedbackType.notSatisfiable,
                otherParty: serverName,
                onDismiss: popToHome,
              );
            }
          case SessionStatus.requestIssuancePermission:
            return IssuancePermission(
              satisfiable: session.satisfiable!,
              issuedCredentials: session.issuedCredentials!,
              onDismiss: () => _dismissSession(),
              onGivePermission: () => _giveIssuancePermission(session),
            );
          case SessionStatus.requestPin:
            return SessionPinScreen(
              sessionID: widget.arguments.sessionID,
              title: FlutterI18n.translate(context, _getAppBarTitle(session.isIssuanceSession)),
            );
          case SessionStatus.error:
            HapticFeedback.heavyImpact();
            return _buildErrorScreen(session);
          case SessionStatus.success:
            HapticFeedback.mediumImpact();
            return _buildFinished(session);
          case SessionStatus.canceled:
            return _buildFinished(session);
          default:
            return _buildLoadingScreen(session.isIssuanceSession);
        }
      });
}

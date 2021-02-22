import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/native_events.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:irmamobile/src/screens/error/session_error_screen.dart';
import 'package:irmamobile/src/screens/issue_wizard/issue_wizard.dart';
import 'package:irmamobile/src/screens/pin/session_pin_screen.dart';
import 'package:irmamobile/src/screens/session/call_info_screen.dart';
import 'package:irmamobile/src/screens/session/session.dart';
import 'package:irmamobile/src/screens/session/widgets/arrow_back_screen.dart';
import 'package:irmamobile/src/screens/session/widgets/disclosure_feedback_screen.dart';
import 'package:irmamobile/src/screens/session/widgets/disclosure_permission.dart';
import 'package:irmamobile/src/screens/session/widgets/issuance_permission.dart';
import 'package:irmamobile/src/screens/session/widgets/session_scaffold.dart';
import 'package:irmamobile/src/util/combine.dart';
import 'package:irmamobile/src/util/navigation.dart';
import 'package:irmamobile/src/util/translated_text.dart';
import 'package:irmamobile/src/widgets/action_feedback.dart';
import 'package:irmamobile/src/widgets/loading_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class SessionScreen extends StatefulWidget {
  static const String routeName = "/session";

  final SessionScreenArguments arguments;

  const SessionScreen({this.arguments}) : super();

  @override
  State<SessionScreen> createState() {
    switch (arguments.sessionType) {
      case "issuing":
      case "disclosing":
      case "signing":
      case "redirect":
        return _SessionScreenState();
      default:
        return _UnknownSessionScreenState();
    }
  }
}

class _UnknownSessionScreenState extends State<SessionScreen> {
  @override
  Widget build(BuildContext context) => ActionFeedback(
        success: false,
        title: TranslatedText(
          "session.unknown_session_type.title",
          style: Theme.of(context).textTheme.headline2,
        ),
        explanation: const TranslatedText(
          "session.unknown_session_type.explanation",
          textAlign: TextAlign.center,
        ),
        onDismiss: () => popToWallet(context),
      );
}

class _SessionScreenState extends State<SessionScreen> {
  final IrmaRepository _repo = IrmaRepository.get();

  Stream<SessionState> _sessionStateStream;

  final ValueNotifier<bool> _displayArrowBack = ValueNotifier<bool>(false);

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
    });
    super.dispose();
  }

  String _getAppBarTitle(bool isIssuance) {
    return isIssuance ? "issuance.title" : "disclosure.title";
  }

  void _dispatchSessionEvent(SessionEvent event, {bool isBridgedEvent = true}) {
    event.sessionID = widget.arguments.sessionID;
    _repo.dispatch(event, isBridgedEvent: isBridgedEvent);
  }

  void _dismissSession() {
    _dispatchSessionEvent(DismissSessionEvent());
  }

  void _givePermission(SessionState session) {
    if (session.status == SessionStatus.requestDisclosurePermission && session.isIssuanceSession) {
      _dispatchSessionEvent(ContinueToIssuanceEvent(), isBridgedEvent: false);
    } else {
      _dispatchSessionEvent(RespondPermissionEvent(
        proceed: true,
        disclosureChoices: session.disclosureChoices,
      ));
    }
  }

  bool _isSpecialIssuanceSession(SessionState session) {
    if (session.issuedCredentials == null) {
      return false;
    }
    if (session.didIssueInappCredential) {
      return true;
    }

    final creds = [
      "pbdf.gemeente.personalData",
      "pbdf.sidn-pbdf.email",
      "pbdf.pbdf.email",
      "pbdf.pbdf.mobilenumber",
      "pbdf.pbdf.ideal",
      "pbdf.pbdf.idin",
    ];
    return session.issuedCredentials.where((credential) => creds.contains(credential.info.fullId)).isNotEmpty;
  }

  Widget _buildFinishedContinueSecondDevice(SessionState session) {
    // In case of issuance, always return to the wallet screen.
    if (session.isIssuanceSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) => popToWallet(context));
      return _buildLoadingScreen(true);
    }

    // In case of a disclosure session, return to the wallet after showing a feedback screen.
    final serverName = session.serverName?.name?.translate(FlutterI18n.currentLocale(context).languageCode) ?? "";
    final feedbackType =
        session.status == SessionStatus.success ? DisclosureFeedbackType.success : DisclosureFeedbackType.canceled;
    return DisclosureFeedbackScreen(
      feedbackType: feedbackType,
      otherParty: serverName,
      popToWallet: popToWallet,
    );
  }

  Widget _buildFinishedReturnPhoneNumber(SessionState session) {
    final serverName = session.serverName?.name?.translate(FlutterI18n.currentLocale(context).languageCode) ?? "";

    // Navigate to call info screen when session succeeded.
    // Otherwise cancel the regular way for the particular session type.
    if (session.status == SessionStatus.success) {
      return CallInfoScreen(
        otherParty: serverName,
        clientReturnURL: session.clientReturnURL,
        popToWallet: popToWallet,
      );
    } else if (session.isIssuanceSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) => popToWallet(context));
      return _buildLoadingScreen(true);
    } else {
      return DisclosureFeedbackScreen(
        feedbackType: DisclosureFeedbackType.canceled,
        otherParty: serverName,
        popToWallet: popToWallet,
      );
    }
  }

  Widget _buildFinished(SessionState session) {
    // In case of issuance during disclosure, another session is open in a screen lower in the stack.
    // Ignore clientReturnUrl in this case (issuance) and pop immediately.
    if (session.isIssuanceSession && widget.arguments.hasUnderlyingSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.of(context).pop());
      return _buildLoadingScreen(true);
    }

    if (session.continueOnSecondDevice && !session.isReturnPhoneNumber) {
      return _buildFinishedContinueSecondDevice(session);
    }

    if (session.isReturnPhoneNumber) {
      return _buildFinishedReturnPhoneNumber(session);
    }

    final popToMainScreen = widget.arguments.wizardActive ? popToWizard : popToWallet;

    // It concerns a mobile session.
    if (session.clientReturnURL != null) {
      // If there is a return URL, navigate to it when we're done; canLaunch check is already
      // done in the session repository, so we know for sure this url is valid.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // When being in a disclosure, we can continue to underlying sessions in this case;
        // hasUnderlyingSession during issuance is handled at the beginning of _buildFinished, so
        // we don't have to explicitly exclude issuance here.
        if (Uri.parse(session.clientReturnURL).queryParameters.containsKey("inapp")) {
          widget.arguments.hasUnderlyingSession ? Navigator.of(context).pop() : popToMainScreen(context);
          if (session.inAppCredential != null && session.inAppCredential != "") {
            _repo.expectInactivationForCredentialType(session.inAppCredential);
          }
          _repo.openURLinAppBrowser(session.clientReturnURL);
        } else {
          _repo.openURLinExternalBrowser(context, session.clientReturnURL);
          widget.arguments.hasUnderlyingSession ? Navigator.of(context).pop() : popToMainScreen(context);
        }
      });
    } else if (widget.arguments.wizardActive || _isSpecialIssuanceSession(session)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => popToMainScreen(context));
    } else if (widget.arguments.hasUnderlyingSession) {
      // In case of a disclosure having an underlying session we only continue to underlying session
      // if it is a mobile session and there was no clientReturnUrl.
      WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.of(context).pop());
    } else if (Platform.isIOS) {
      // On iOS show a screen to press the return arrow in the top-left corner,
      return ArrowBack();
    } else {
      // On Android just background the app to let the user return to the previous activity
      WidgetsBinding.instance.addPostFrameCallback((_) {
        IrmaRepository.get().bridgedDispatch(AndroidSendToBackgroundEvent());
        popToWallet(context);
      });
    }
    return _buildLoadingScreen(session.isIssuanceSession);
  }

  Widget _buildErrorScreen(SessionState session) => ValueListenableBuilder(
        valueListenable: _displayArrowBack,
        builder: (BuildContext context, bool displayArrowBack, Widget child) {
          if (displayArrowBack) {
            return ArrowBack();
          }
          return child;
        },
        child: SessionErrorScreen(
          error: session.error,
          onTapClose: () {
            if (widget.arguments.wizardActive) {
              popToWizard(context);
            } else if (session.continueOnSecondDevice) {
              popToWallet(context);
            } else if (session.clientReturnURL != null && !session.isReturnPhoneNumber) {
              // canLaunch check is already done in the session repository.
              launch(session.clientReturnURL, forceSafariVC: false);
              popToWallet(context);
            } else {
              if (Platform.isIOS) {
                _displayArrowBack.value = true;
              } else {
                IrmaRepository.get().bridgedDispatch(AndroidSendToBackgroundEvent());
                popToWallet(context);
              }
            }
          },
        ),
      );

  Widget _buildLoadingScreen(bool isIssuance) => SessionScaffold(
        body: Column(children: [
          Center(
            child: LoadingIndicator(),
          ),
        ]),
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
          return _buildLoadingScreen(widget.arguments.sessionType == "issuing");
        }

        // Prevent stealing focus from pin screen in case app is locked
        final locked = snapshot.data.a;
        Navigator.of(context).focusScopeNode.canRequestFocus = !locked;

        final session = snapshot.data.b;

        switch (session.status) {
          case SessionStatus.requestDisclosurePermission:
            return DisclosurePermission(
              session: session,
              onDismiss: () => _dismissSession(),
              onGivePermission: () => _givePermission(session),
              dispatchSessionEvent: _dispatchSessionEvent,
            );
          case SessionStatus.requestIssuancePermission:
            return IssuancePermission(
              satisfiable: session.satisfiable,
              issuedCredentials: session.issuedCredentials,
              onDismiss: () => _dismissSession(),
              onGivePermission: () => _givePermission(session),
            );
          case SessionStatus.requestPin:
            return SessionPinScreen(
              sessionID: widget.arguments.sessionID,
              title: FlutterI18n.translate(context, _getAppBarTitle(session.isIssuanceSession)),
            );
          case SessionStatus.error:
            return _buildErrorScreen(session);
          case SessionStatus.success:
          case SessionStatus.canceled:
            return _buildFinished(session);
          default:
            return _buildLoadingScreen(session.isIssuanceSession);
        }
      });
}

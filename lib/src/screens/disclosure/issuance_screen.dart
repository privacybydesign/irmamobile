import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/native_events.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:irmamobile/src/screens/disclosure/call_info_screen.dart';
import 'package:irmamobile/src/screens/disclosure/session.dart';
import 'package:irmamobile/src/screens/disclosure/widgets/arrow_back_screen.dart';
import 'package:irmamobile/src/screens/history/widgets/issuing_detail.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import 'disclosure_screen.dart';

class IssuanceScreen extends StatefulWidget {
  static const String routeName = "/issuance";

  final SessionScreenArguments arguments;

  const IssuanceScreen({this.arguments}) : super();

  @override
  _IssuanceScreenState createState() => _IssuanceScreenState();
}

class _IssuanceScreenState extends State<IssuanceScreen> {
  final IrmaRepository repo = IrmaRepository.get();
  Stream<SessionState> sessionStateStream;
  StreamSubscription<SessionState> sessionStateSubscription;
  int sessionID;
  bool displayArrowBack = false;
  SessionStatus _screenStatus = SessionStatus.uninitialized;

  @override
  void initState() {
    super.initState();
    sessionID = widget.arguments.sessionID;
    sessionStateStream = repo.getSessionState(widget.arguments.sessionID);

    sessionStateSubscription = sessionStateStream.listen((session) {
      // Do nothing if status did not change.
      if (_screenStatus == session.status) {
        return;
      }
      _screenStatus = session.status;

      if (_screenStatus == SessionStatus.requestDisclosurePermission) {
        // If disclosure permission is asked, hand over control to disclosure screen.
        Navigator.of(context).pushNamedAndRemoveUntil(
          DisclosureScreen.routeName,
          ModalRoute.withName(WalletScreen.routeName),
          arguments: widget.arguments,
        );
      }

      if (_screenStatus == SessionStatus.requestPin) {
        pushSessionPinScreen(context, sessionID, 'issuance.title');
      }

      if (_screenStatus == SessionStatus.error) {
        _handleError(session);
      }

      if ([SessionStatus.success, SessionStatus.canceled].contains(_screenStatus)) {
        _handleFinished(session);
      }
    });
  }

  @override
  void dispose() {
    sessionStateSubscription.cancel();
    if (_screenStatus == SessionStatus.requestIssuancePermission) {
      _dismissSession();
    }
    super.dispose();
  }

  Widget _buildPermissionWidget(SessionState session) {
    return ListView(
      padding: EdgeInsets.all(IrmaTheme.of(context).smallSpacing),
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: IrmaTheme.of(context).mediumSpacing,
            horizontal: IrmaTheme.of(context).smallSpacing,
          ),
          child: Text(
            FlutterI18n.plural(context, 'issuance.header', session.issuedCredentials.length),
            style: Theme.of(context).textTheme.body1,
          ),
        ),
        IssuingDetail(session.issuedCredentials),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (displayArrowBack) {
      return ArrowBack();
    }

    return Scaffold(
      appBar: IrmaAppBar(
        title: Text(FlutterI18n.translate(context, 'issuance.title')),
        leadingCancel: () => _dismissSession(),
      ),
      backgroundColor: IrmaTheme.of(context).grayscaleWhite,
      bottomNavigationBar: _buildNavigationBar(),
      body: StreamBuilder(
        stream: sessionStateStream,
        builder: (BuildContext context, AsyncSnapshot<SessionState> sessionStateSnapshot) {
          if (!sessionStateSnapshot.hasData) {
            return buildLoadingIndicator();
          }

          final session = sessionStateSnapshot.data;
          if (session.status == SessionStatus.requestIssuancePermission) {
            return _buildPermissionWidget(session);
          }

          return buildLoadingIndicator();
        },
      ),
    );
  }

  void _dispatchSessionEvent(SessionEvent event, {bool isBridgedEvent = true}) {
    event.sessionID = sessionID;
    repo.dispatch(event, isBridgedEvent: isBridgedEvent);
  }

  // Handle errors. The return code is replicated here as we start
  // with a somewhat different situation, having an extra screen
  // on top of the stack
  void _handleError(SessionState session) {
    toErrorScreen(context, session.error, () async {
      if (session.continueOnSecondDevice) {
        popToWallet(context);
      } else if (session.clientReturnURL != null &&
          !session.isReturnPhoneNumber &&
          await canLaunch(session.clientReturnURL)) {
        launch(session.clientReturnURL, forceSafariVC: false);
        popToWallet(context);
      } else {
        if (Platform.isIOS) {
          setState(() => displayArrowBack = true);
          Navigator.of(context).pop(); // pop error screen
        } else {
          IrmaRepository.get().bridgedDispatch(AndroidSendToBackgroundEvent());
          popToWallet(context);
        }
      }
    });
  }

  Future<void> _handleFinished(SessionState session) async {
    final serverName = session.serverName.translate(FlutterI18n.currentLocale(context).languageCode);
    await Future.delayed(const Duration(seconds: 1));

    if (session.continueOnSecondDevice && !session.isReturnPhoneNumber) {
      // If this is a session on a second screen, return to the wallet
      popToWallet(context);
      // TODO: Maybe show some error screen on error or cancel
    } else if (session.clientReturnURL != null &&
        !session.isReturnPhoneNumber &&
        await canLaunch(session.clientReturnURL)) {
      // If there is a return URL, navigate to it when we're done
      launch(session.clientReturnURL, forceSafariVC: false);
      popToWallet(context);
    } else if(session.isReturnPhoneNumber) {
      _pushInfoCallScreen(serverName, session.clientReturnURL);
    } else {
      // Otherwise, on iOS show a screen to press the return arrow in the top-left corner,
      // and on Android just background the app to let the user return to the previous activity
      if (session.issuedCredentials
          .where((credential) => [
                "pbdf.gemeente.personalData",
                "pbdf.pbdf.email",
                "pbdf.pbdf.mobilenumber",
                "pbdf.pbdf.ideal",
                "pbdf.pbdf.idin"
              ].contains(credential.info.fullId))
          .isNotEmpty) {
        popToWallet(context);
        // Do not go back to browser for idin, iban, phone, email and gemeente-issued personaldata credentials
      } else if (Platform.isIOS) {
        setState(() => displayArrowBack = true);
      } else {
        IrmaRepository.get().bridgedDispatch(AndroidSendToBackgroundEvent());
        popToWallet(context);
      }
    }
  }

  void _pushInfoCallScreen(String otherParty, String clientReturnURL) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => CallInfoScreen(
        otherParty: otherParty,
        clientReturnURL: clientReturnURL,
        popToWallet: popToWallet,
      ),
    ));
  }

  void _givePermission(SessionState session) {
    _dispatchSessionEvent(RespondPermissionEvent(
      proceed: true,
      disclosureChoices: session.disclosureChoices,
    ));
  }

  void _dismissSession() {
    _dispatchSessionEvent(RespondPermissionEvent(
      proceed: false,
      disclosureChoices: [],
    ));
  }

  Widget _buildNavigationBar() {
    return StreamBuilder<SessionState>(
      stream: sessionStateStream,
      builder: (context, sessionStateSnapshot) {
        if (!sessionStateSnapshot.hasData ||
            sessionStateSnapshot.data.status != SessionStatus.requestIssuancePermission) {
          return Container(height: 0);
        }

        final state = sessionStateSnapshot.data;
        return state.satisfiable
            ? IrmaBottomBar(
                primaryButtonLabel: FlutterI18n.translate(context, "session.navigation_bar.yes"),
                onPrimaryPressed: () => _givePermission(state),
                secondaryButtonLabel: FlutterI18n.translate(context, "session.navigation_bar.no"),
                onSecondaryPressed: () => popToWallet(context),
              )
            : IrmaBottomBar(
                primaryButtonLabel: FlutterI18n.translate(context, "session.navigation_bar.back"),
                onPrimaryPressed: () => popToWallet(context),
              );
      },
    );
  }
}

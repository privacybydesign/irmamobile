import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:irmamobile/src/screens/disclosure/session.dart';
import 'package:irmamobile/src/screens/disclosure/widgets/arrow_back_screen.dart';
import 'package:irmamobile/src/screens/history/widgets/issuing_detail.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:url_launcher/url_launcher.dart';

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
  int sessionID;
  bool displayArrowBack = false;

  @override
  void initState() {
    super.initState();
    sessionID = widget.arguments.sessionID;
    sessionStateStream = repo.getSessionState(widget.arguments.sessionID);

    // Make sure PIN is asked when necessary
    sessionStateStream
        .firstWhere((session) => session.requestPin == true)
        .then((session) => pushSessionPinScreen(context, sessionID, 'issuance.title'));

    // Handle errors. The return code is replicated here as we start
    // with a somewhat different situation, having an extra screen
    // on top of the stack
    sessionStateStream.firstWhere((session) => session.status == SessionStatus.error).then((session) {
      toErrorScreen(context, session.error, () {
        (() async {
          if (session.continueOnSecondDevice) {
            popToWallet(context);
          } else if (session.clientReturnURL != null && await canLaunch(session.clientReturnURL)) {
            launch(session.clientReturnURL, forceSafariVC: false);
            popToWallet(context);
          } else {
            if (Platform.isIOS) {
              setState(() => displayArrowBack = true);
              Navigator.of(context).pop(); // pop error screen
            } else {
              SystemNavigator.pop();
              popToWallet(context);
            }
          }
        })();
      });
    });

    _handleFinished();
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
          if (session.status == SessionStatus.requestPermission) {
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

  Future<void> _handleFinished() async {
    // When the session has completed, wait one second to display a message
    final session = await sessionStateStream.firstWhere((session) {
      switch (session.status) {
        case SessionStatus.success:
        case SessionStatus.canceled:
          return true;
        default:
          return false;
      }
    });
    await Future.delayed(const Duration(seconds: 1));

    if (session.continueOnSecondDevice) {
      // If this is a session on a second screen, return to the wallet
      popToWallet(context);
      // TODO: Maybe show some error screen on error or cancel
    } else if (session.clientReturnURL != null && await canLaunch(session.clientReturnURL)) {
      // If there is a return URL, navigate to it when we're done
      launch(session.clientReturnURL, forceSafariVC: false);
      popToWallet(context);
    } else {
      // Otherwise, on iOS show a screen to press the return arrow in the top-left corner,
      // and on Android just background the app to let the user return to the previous activity
      if (Platform.isIOS) {
        setState(() => displayArrowBack = true);
      } else {
        SystemNavigator.pop();
        popToWallet(context);
      }
    }
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

  void _declinePermission(BuildContext context, String otherParty) {
    _dismissSession();
    popToWallet(context);
  }

  Widget _buildNavigationBar() {
    return StreamBuilder<SessionState>(
      stream: sessionStateStream,
      builder: (context, sessionStateSnapshot) {
        if (!sessionStateSnapshot.hasData || sessionStateSnapshot.data.status != SessionStatus.requestPermission) {
          return Container(height: 0);
        }

        final state = sessionStateSnapshot.data;
        return state.satisfiable
            ? IrmaBottomBar(
                primaryButtonLabel: FlutterI18n.translate(context, "session.navigation_bar.yes"),
                onPrimaryPressed: () => _givePermission(state),
                secondaryButtonLabel: FlutterI18n.translate(context, "session.navigation_bar.no"),
                onSecondaryPressed: () => _declinePermission(context, state.serverName.translate(_lang)),
              )
            : IrmaBottomBar(
                primaryButtonLabel: FlutterI18n.translate(context, "session.navigation_bar.back"),
                onPrimaryPressed: () => _declinePermission(context, state.serverName.translate(_lang)),
              );
      },
    );
  }
}

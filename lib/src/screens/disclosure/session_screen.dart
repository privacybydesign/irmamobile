import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:irmamobile/src/screens/disclosure/widgets/arrow_back_screen.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:irmamobile/src/widgets/loading_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class SessionScreenArguments {
  final int sessionID;
  final String sessionType;

  SessionScreenArguments({this.sessionID, this.sessionType});
}

abstract class SessionWidgetState<T extends StatefulWidget> extends State<T> {
  final String _lang = "nl"; // TODO: this shouldn't be hardcoded.

  final IrmaRepository repo = IrmaRepository.get();
  Stream<SessionState> sessionStateStream;
  int sessionID;
  bool displayArrowBack = false;

  String get title;
  Widget buildContents(SessionState session);
  Widget buildHeader(SessionState session);
  void declinePermission(BuildContext context, String otherParty);
  void finishOnSecondDevice(BuildContext context, String otherParty);

  @override
  Widget build(BuildContext context) {
    if (displayArrowBack) {
      return ArrowBack();
    }

    return Scaffold(
      appBar: IrmaAppBar(
        title: Text(FlutterI18n.translate(context, title)),
      ),
      backgroundColor: IrmaTheme.of(context).grayscaleWhite,
      bottomNavigationBar: _buildNavigationBar(),
      body: StreamBuilder(
        stream: sessionStateStream,
        builder: (BuildContext context, AsyncSnapshot<SessionState> sessionStateSnapshot) {
          if (!sessionStateSnapshot.hasData) {
            return _buildLoadingIndicator();
          }

          final session = sessionStateSnapshot.data;
          if (session.status == SessionStatus.requestPermission) {
            return _buildPermissionWidget(session);
          }

          return _buildLoadingIndicator();
        },
      ),
    );
  }

  @protected
  void dispatchSessionEvent(SessionEvent event, {bool isBridgedEvent = true}) {
    event.sessionID = sessionID;
    repo.dispatch(event, isBridgedEvent: isBridgedEvent);
  }

  @protected
  void dismissSession() {
    dispatchSessionEvent(DismissSessionEvent());
  }

  @protected
  void popToWallet(BuildContext context) {
    Navigator.of(context).popUntil(
      ModalRoute.withName(
        WalletScreen.routeName,
      ),
    );
  }

  @protected
  void givePermission(SessionState session) {
    dispatchSessionEvent(RespondPermissionEvent(
      proceed: true,
      disclosureChoices: session.disclosureChoices,
    ));
  }

  @protected
  Future<void> handleSuccess() async {
    // When the session has completed, wait one second to display a message
    final session = await sessionStateStream.firstWhere((session) => session.status == SessionStatus.success);
    await Future.delayed(const Duration(seconds: 1));

    if (session.continueOnSecondDevice) {
      // If this is a session on a second screen, return to the wallet possibly after showing a feedback screen
      finishOnSecondDevice(context, session.serverName.translate(_lang));
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
                onPrimaryPressed: state.canDisclose ? () => _givePermission(state) : null,
                secondaryButtonLabel: FlutterI18n.translate(context, "session.navigation_bar.no"),
                onSecondaryPressed: () => declinePermission(context, state.serverName.translate(_lang)),
              )
            : IrmaBottomBar(
                primaryButtonLabel: FlutterI18n.translate(context, "session.navigation_bar.back"),
                onPrimaryPressed: () => declinePermission(context, state.serverName.translate(_lang)),
              );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(children: [
      Center(
        child: LoadingIndicator(),
      ),
    ]);
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
          child: buildHeader(session),
        ),
        buildContents(session),
      ],
    );
  }

  void _givePermission(SessionState session) {
    dispatchSessionEvent(RespondPermissionEvent(
      proceed: true,
      disclosureChoices: session.disclosureChoices,
    ));
  }
}

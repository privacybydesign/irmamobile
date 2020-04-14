import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/pin/session_pin_screen.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';
import 'package:irmamobile/src/widgets/loading_indicator.dart';

class SessionScreenArguments {
  final int sessionID;
  final String sessionType;

  SessionScreenArguments({this.sessionID, this.sessionType});
}

void popToWallet(BuildContext context) {
  Navigator.of(context).popUntil(
    ModalRoute.withName(
      WalletScreen.routeName,
    ),
  );
}

Widget buildLoadingIndicator() {
  return Column(children: [
    Center(
      child: LoadingIndicator(),
    ),
  ]);
}

void pushSessionPinScreen(BuildContext context, int sessionID, String title) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (context) => SessionPinScreen(
      sessionID: sessionID,
      title: FlutterI18n.translate(context, title),
    ),
  ));
}

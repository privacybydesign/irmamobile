import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';

class SessionScreenArguments {
  final int sessionID;
  final String sessionType;
  final bool hasUnderlyingSession;

  SessionScreenArguments({this.sessionID, this.sessionType, this.hasUnderlyingSession});
}

void popToWallet(BuildContext context) {
  Navigator.of(context).popUntil(
    ModalRoute.withName(
      WalletScreen.routeName,
    ),
  );
}

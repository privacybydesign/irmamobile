import 'package:flutter/widgets.dart';
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

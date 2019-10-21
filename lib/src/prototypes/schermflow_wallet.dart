import 'package:flutter/material.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';

void startSchermflowWallet(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(builder: (context) => WalletScreen()));
}

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/screens/issue_wizard/issue_wizard.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';

void popToWallet(BuildContext context) {
  Navigator.of(context).popUntil(
    ModalRoute.withName(
      WalletScreen.routeName,
    ),
  );
}

void popToWizard(BuildContext context) {
  Navigator.of(context).popUntil(
    ModalRoute.withName(
      IssueWizardScreen.routeName,
    ),
  );
}

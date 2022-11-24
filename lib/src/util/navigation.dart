import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/screens/home/home_screen.dart';
import 'package:irmamobile/src/screens/issue_wizard/issue_wizard.dart';

void popToHome(BuildContext context) {
  Navigator.of(context).popUntil(
    ModalRoute.withName(
      HomeScreen.routeName,
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

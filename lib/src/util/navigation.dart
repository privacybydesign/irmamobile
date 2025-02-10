import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../screens/issue_wizard/issue_wizard.dart';

void popToWizard(BuildContext context) {
  Navigator.of(context).popUntil(
    ModalRoute.withName(
      IssueWizardScreen.routeName,
    ),
  );
}

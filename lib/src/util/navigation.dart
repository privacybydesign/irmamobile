import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../routing.dart';

void popToWizard(BuildContext context) {
  Navigator.of(context).popUntil(ModalRoute.withName('/issue_wizard'));
}

void goToHomeWithoutTransition(BuildContext context) {
  HomeTransitionStyleProvider.performInstantTransitionToHome(context);
}

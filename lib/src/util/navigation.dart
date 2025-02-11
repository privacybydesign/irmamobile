import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void popToWizard(BuildContext context) {
  Navigator.of(context).popUntil(ModalRoute.withName('/issue_wizard'));
}

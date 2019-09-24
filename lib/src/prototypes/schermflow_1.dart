import 'package:flutter/material.dart';
import 'package:irmamobile/src/screens/enrollment/enrollment.dart';

void startSchermflow1(BuildContext context) {
  // TODO: Let this Enrollment screen act on mock data.
  //
  // TODO: Detect when Enrollment is done, then return from this navigation,
  // back to prototypes menu.
  Navigator.of(context).push(MaterialPageRoute(builder: (context) => Enrollment()));
}

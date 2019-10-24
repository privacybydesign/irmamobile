import 'package:flutter/material.dart';
import 'package:irmamobile/src/screens/enrollment/enrollment_screen.dart';

void startSchermflow1(BuildContext context) {
  // TODO: Detect when Enrollment is done, then return from this navigation,
  // back to prototypes menu.
  Navigator.of(context).push(MaterialPageRoute(builder: (context) => EnrollmentScreen()));
}

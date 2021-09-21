// This code is not null safe yet.
// @dart=2.11

import 'package:irmamobile/src/models/session.dart';

class PinState {
  bool authenticated;
  bool authenticateInProgress;
  DateTime blockedUntil;
  bool pinInvalid;
  SessionError error;
  int remainingAttempts;

  PinState({
    this.authenticated = false,
    this.authenticateInProgress = false,
    this.blockedUntil,
    this.pinInvalid = false,
    this.error,
    this.remainingAttempts,
  });
}

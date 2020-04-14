class PinState {
  bool authenticated;
  bool authenticateInProgress;
  DateTime blockedUntil;
  bool pinInvalid;
  String errorMessage;
  int remainingAttempts;

  PinState({
    this.authenticated = false,
    this.authenticateInProgress = false,
    this.blockedUntil,
    this.pinInvalid = false,
    this.errorMessage,
    this.remainingAttempts,
  });
}

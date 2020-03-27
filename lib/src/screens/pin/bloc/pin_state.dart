class PinState {
  bool locked;
  bool unlockInProgress;
  DateTime blockedUntil;
  bool pinInvalid;
  String errorMessage;
  int remainingAttempts;

  PinState({
    this.locked = true,
    this.unlockInProgress = false,
    this.blockedUntil,
    this.pinInvalid = false,
    this.errorMessage,
    this.remainingAttempts,
  });

  PinState copyWith({
    // bool locked,
    bool unlockInProgress,
    // DateTime blockedUntil,
    // bool pinInvalid,
    // String errorMessage,
    // int remainingAttempts,
  }) {
    return PinState(
      // locked: locked ?? this.locked,
      unlockInProgress: unlockInProgress ?? this.unlockInProgress,
      // blockedUntil: blockedUntil ?? this.blockedUntil,
      // pinInvalid: pinInvalid ?? this.pinInvalid,
      // errorMessage: errorMessage ?? this.errorMessage,
      // remainingAttempts: remainingAttempts ?? this.remainingAttempts,
    );
  }
}

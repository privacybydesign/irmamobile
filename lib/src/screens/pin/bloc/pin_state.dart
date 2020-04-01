class PinState {
  bool locked;
  bool unlockInProgress;
  bool lockInProgress;
  DateTime blockedUntil;
  bool pinInvalid;
  String errorMessage;
  int remainingAttempts;

  PinState({
    this.locked = true,
    this.unlockInProgress = false,
    this.lockInProgress = false,
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

  bool get isBlocked {
    if (remainingAttempts != null && remainingAttempts > 0) {
      return false;
    }
    if (blockedUntil == null) {
      return false;
    }
    if (blockedUntil.isBefore(DateTime.now())) {
      return false;
    }
    return true;
  }
}

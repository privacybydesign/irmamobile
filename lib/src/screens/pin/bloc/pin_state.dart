class PinState {
  bool locked;
  bool unlockInProgress;
  DateTime blockedUntil;
  bool pinInvalid;
  String errorMessage;
  int remainingAttempts;

  PinState({
    this.locked,
    this.unlockInProgress,
    this.blockedUntil,
    this.pinInvalid,
    this.errorMessage,
    this.remainingAttempts,
  });

  PinState copyWith(
      {bool locked,
      bool unlockInProgress,
      DateTime blockedUntil,
      bool pinInvalid,
      String errorMessage,
      int remainingAttempts}) {
    return PinState(
      locked: locked ?? this.locked,
      unlockInProgress: unlockInProgress ?? this.unlockInProgress,
      blockedUntil: blockedUntil ?? this.blockedUntil,
      pinInvalid: pinInvalid ?? this.pinInvalid,
      errorMessage: errorMessage ?? this.errorMessage,
      remainingAttempts: remainingAttempts ?? this.remainingAttempts,
    );
  }

  get isBlocked => blockedUntil?.isAfter(DateTime.now()) ?? false;
}

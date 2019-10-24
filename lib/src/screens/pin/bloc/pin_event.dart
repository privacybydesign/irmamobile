class PinEvent {}

// Unlock event is sent by UI to initiate an unlock sequence.
class Unlock extends PinEvent {
  String pin;
  Unlock(this.pin);
}

// Lock event is sent by UI to pro-actively lock.
class Lock extends PinEvent {}

// Locked indicates that the irmago repository was locked.
class Locked extends PinEvent {}

// Unlocked indicates that the irmago repository was unlocked.
class Unlocked extends PinEvent {}

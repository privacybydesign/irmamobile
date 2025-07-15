enum PinEventType { oldPinEntered, newPinChosen, newPinConfirmed }

class PinEvent {
  final String pin;
  final PinEventType type;
  const PinEvent(this.pin, this.type);
}

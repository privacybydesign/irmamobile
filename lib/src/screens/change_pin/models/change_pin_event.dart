abstract class PinEvent {
  final String pin;
  PinEvent(this.pin);
}

class OldPinEntered extends PinEvent {
  OldPinEntered({required String pin}) : super(pin);

  @override
  String toString() => 'OldPinEntered { pin: ${'*' * pin.length} }';
}

class NewPinChosen extends PinEvent {
  NewPinChosen({required pin}) : super(pin);

  @override
  String toString() => 'NewPinChosen { pin: ${'*' * pin.length} }';
}

class NewPinConfirmed extends PinEvent {
  NewPinConfirmed({required String pin}) : super(pin);

  @override
  String toString() => 'NewPinConfirmed { pin: ${'*' * pin.length} }';
}

import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

class OldPinEntered extends Equatable {
  final String pin;

  OldPinEntered({@required this.pin}) : super([pin]);

  @override
  String toString() => 'OldPinEntered { pin: ${'*' * pin.length} }';
}

class OldPinValidated extends Equatable {
  final bool valid;

  OldPinValidated({@required this.valid}) : super([valid]);

  @override
  String toString() => 'OldPinValidated { valid: $valid }';
}

class NewPinChosen extends Equatable {
  final String pin;

  NewPinChosen({@required this.pin}) : super([pin]);

  @override
  String toString() => 'NewPinChosen { pin: ${'*' * pin.length} }';
}

class ToggleLongPin extends Equatable {
  @override
  String toString() => 'ToggleLongPin';
}

class NewPinConfirmed extends Equatable {
  final String pin;

  NewPinConfirmed({@required this.pin}) : super([pin]);

  @override
  String toString() => 'NewPinConfirmed { pin: ${'*' * pin.length} }';
}

class ChangePinCanceled extends Equatable {
  @override
  String toString() => 'ChangePinCanceled';
}

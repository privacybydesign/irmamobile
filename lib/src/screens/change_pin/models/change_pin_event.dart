import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

class OldPinEntered extends Equatable {
  final String pin;

  OldPinEntered({@required this.pin}) : super([pin]);

  @override
  String toString() => 'OldPinEntered { pin: ${'*' * pin.length} }';
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

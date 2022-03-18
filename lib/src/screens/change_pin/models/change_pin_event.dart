import 'package:equatable/equatable.dart';

class OldPinEntered extends Equatable {
  final String pin;

  const OldPinEntered({required this.pin});

  @override
  String toString() => 'OldPinEntered { pin: ${'*' * pin.length} }';

  @override
  List<Object> get props => [pin];
}

class NewPinChosen extends Equatable {
  final String pin;

  const NewPinChosen({required this.pin});

  @override
  String toString() => 'NewPinChosen { pin: ${'*' * pin.length} }';

  @override
  List<Object> get props => [pin];
}

class ToggleLongPin extends Equatable {
  @override
  String toString() => 'ToggleLongPin';

  @override
  List<Object> get props => [];
}

class NewPinConfirmed extends Equatable {
  final String pin;

  const NewPinConfirmed({required this.pin});

  @override
  String toString() => 'NewPinConfirmed { pin: ${'*' * pin.length} }';

  @override
  List<Object> get props => [pin];
}

class ChangePinCanceled extends Equatable {
  @override
  String toString() => 'ChangePinCanceled';

  @override
  List<Object> get props => [];
}

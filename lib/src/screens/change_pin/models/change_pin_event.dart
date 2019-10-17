import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

abstract class ChangePinEvent extends Equatable {
  ChangePinEvent([List props = const []]) : super(props);
}

class OldPinEntered extends ChangePinEvent {
  final String pin;

  OldPinEntered({@required this.pin}) : super([pin]);

  @override
  String toString() => 'OldPinEntered { pin: $pin }';
}

class NewPinChosen extends ChangePinEvent {
  final String pin;

  NewPinChosen({@required this.pin}) : super([pin]);

  @override
  String toString() => 'NewPinChosen { pin: $pin }';
}

class NewPinConfirmed extends ChangePinEvent {
  final String pin;

  NewPinConfirmed({@required this.pin}) : super([pin]);

  @override
  String toString() => 'NewPinConfirmed { pin: $pin }';
}

class ChangePinCanceled extends ChangePinEvent {
  @override
  String toString() => 'ChangePinCanceled';
}

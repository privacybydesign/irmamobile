import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

abstract class EnrollmentEvent extends Equatable {
  EnrollmentEvent([List props = const []]) : super(props);
}

class PinChosen extends EnrollmentEvent {
  final String pin;

  PinChosen({@required this.pin}) : super([pin]);

  @override
  String toString() => 'PinChosen { pin: $pin }';
}

class PinConfirmed extends EnrollmentEvent {
  final String pin;

  PinConfirmed({@required this.pin}) : super([pin]);

  @override
  String toString() => 'PinConfirmed { pin: $pin }';
}

class EmailChanged extends EnrollmentEvent {
  final String email;

  EmailChanged({@required this.email}) : super([email]);

  @override
  String toString() => 'EmailChanged';
}

class EmailSubmitted extends EnrollmentEvent {
  @override
  String toString() => 'EmailSubmitted';
}

class EnrollmentCanceled extends EnrollmentEvent {
  @override
  String toString() => 'EnrollmentCanceled';
}

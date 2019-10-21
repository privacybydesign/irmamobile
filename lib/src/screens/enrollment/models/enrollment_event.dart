import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

class PinSubmitted extends Equatable {
  final String pin;

  PinSubmitted({@required this.pin}) : super([pin]);

  @override
  String toString() => 'PinSubmitted { pin: ${'*' * pin.length} }';
}

class ConfirmationPinSubmitted extends Equatable {
  final String pin;

  ConfirmationPinSubmitted({@required this.pin}) : super([pin]);

  @override
  String toString() => 'ConfirmationPinSubmitted { pin: ${'*' * pin.length} }';
}

class EmailChanged extends Equatable {
  final String email;

  EmailChanged({@required this.email}) : super([email]);

  @override
  String toString() => 'EmailChanged';
}

class EmailSubmitted extends Equatable {
  @override
  String toString() => 'EmailSubmitted';
}

class EnrollmentCanceled extends Equatable {
  @override
  String toString() => 'EnrollmentCanceled';
}

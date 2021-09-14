// This code is not null safe yet.
// @dart=2.11

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

class PinSubmitted extends Equatable {
  final String pin;

  const PinSubmitted({@required this.pin});

  @override
  String toString() => 'PinSubmitted { pin: ${'*' * pin.length} }';

  @override
  List<Object> get props => [pin];
}

class ConfirmationPinSubmitted extends Equatable {
  final String pin;

  const ConfirmationPinSubmitted({@required this.pin});

  @override
  String toString() => 'ConfirmationPinSubmitted { pin: ${'*' * pin.length} }';

  @override
  List<Object> get props => [pin];
}

class EmailSubmitted extends Equatable {
  final String email;

  const EmailSubmitted({@required this.email});

  @override
  String toString() => 'EmailSubmitted';

  @override
  List<Object> get props => [email];
}

class EmailSkipped extends Equatable {
  @override
  String toString() => 'EmailSkipped';

  @override
  List<Object> get props => [];
}

class Enroll extends Equatable {
  @override
  String toString() => 'Enroll';

  @override
  List<Object> get props => [];
}

class EnrollmentCanceled extends Equatable {
  @override
  String toString() => 'EnrollmentCanceled';

  @override
  List<Object> get props => [];
}

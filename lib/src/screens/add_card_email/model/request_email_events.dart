import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

abstract class RequestEmailEvent extends Equatable {
  RequestEmailEvent([List props = const []]) : super(props);
}

class RequestAttribute extends RequestEmailEvent {
  final String email;
  final String language;

  RequestAttribute({@required this.email, @required this.language}) : super([email, language]);

  @override
  String toString() => 'Requesting email attribute { email: $email }';
}

class ClearEmail extends RequestEmailEvent {
  ClearEmail() : super([]);

  @override
  String toString() => 'Email cleared';
}

class RequestAgain extends RequestEmailEvent {
  RequestAgain() : super([]);

  @override
  String toString() => 'Request again';
}

class CloseSuccessAlert extends RequestEmailEvent {
  CloseSuccessAlert() : super([]);

  @override
  String toString() => 'Close success alert';
}

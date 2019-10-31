import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class RequestEmailState with EquatableMixin {
  final String irmaEmail;
  final String enteredEmail;
  final bool emailAttributeRequested;
  final bool inProgress;
  final bool emailCouldNotBeSend;
  final bool showSuccessConfirmation;

  RequestEmailState(
      {this.irmaEmail,
      this.enteredEmail,
      this.inProgress,
      this.emailAttributeRequested,
      this.emailCouldNotBeSend,
      this.showSuccessConfirmation});

  RequestEmailState copyWith(
      {String irmaEmail,
      String enteredEmail,
      bool invalidEmail,
      bool inProgress,
      bool emailAttributeRequested,
      bool emailCouldNotBeSend,
      bool showSuccessConfirmation}) {
    return RequestEmailState(
        irmaEmail: irmaEmail ?? this.irmaEmail,
        enteredEmail: enteredEmail ?? this.enteredEmail,
        inProgress: inProgress ?? this.inProgress,
        emailAttributeRequested: emailAttributeRequested ?? this.emailAttributeRequested,
        emailCouldNotBeSend: emailCouldNotBeSend ?? this.emailCouldNotBeSend,
        showSuccessConfirmation: showSuccessConfirmation ?? this.showSuccessConfirmation);
  }

  @override
  String toString() {
    return 'RequestEmailState {irmaEmail: $irmaEmail, enteredEmail: $enteredEmail, inProgress: $inProgress, emailAttributeRequested: $emailAttributeRequested}, emailCouldNotBeSend: $emailCouldNotBeSend, showSuccessConfirmation: $showSuccessConfirmation';
  }

  @override
  List<Object> get props {
    return [irmaEmail, enteredEmail, inProgress, emailAttributeRequested, emailCouldNotBeSend, showSuccessConfirmation];
  }
}

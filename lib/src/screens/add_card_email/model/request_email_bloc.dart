import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:irmamobile/src/screens/add_card_email/model/attribute_requester.dart';
import 'package:irmamobile/src/screens/add_card_email/model/request_email_events.dart';
import 'package:irmamobile/src/screens/add_card_email/model/request_email_state.dart';

class RequestEmailBloc extends Bloc<RequestEmailEvent, RequestEmailState> {
  final RequestEmailState startingState;
  final EmailAttributeRequester attributeRequester;
  final String registrationEmail;
  final Duration showSuccessAlertDuration = const Duration(seconds: 3);
  String _selectedLanguage;

  RequestEmailBloc(this.registrationEmail, this.attributeRequester) : startingState = null;

  RequestEmailBloc.test(this.registrationEmail, this.attributeRequester, this.startingState);

  @override
  RequestEmailState get initialState {
    if (startingState == null) {
      return RequestEmailState().copyWith(
          irmaEmail: registrationEmail,
          enteredEmail: registrationEmail ?? "",
          invalidEmail: false,
          inProgress: false,
          emailCouldNotBeSend: false,
          emailAttributeRequested: false);
    } else {
      return startingState.copyWith();
    }
  }

  @override
  Stream<RequestEmailState> mapEventToState(RequestEmailEvent event) async* {
    if (event is RequestAttribute) {
      yield currentState.copyWith(
        invalidEmail: false,
        inProgress: true,
        enteredEmail: event.email,
        irmaEmail: event.email,
      );
      _selectedLanguage = event.language;
      final success = await attributeRequester.requestAttribute(event.email, _selectedLanguage);
      yield currentState.copyWith(
          emailAttributeRequested: success,
          inProgress: false,
          emailCouldNotBeSend: !success,
          showSuccessConfirmation: success);
      if (success) {
        Future.delayed(showSuccessAlertDuration, () {
          dispatch(CloseSuccessAlert());
        });
      }
    }

    if (event is RequestAgain) {
      if (!currentState.inProgress) {
        yield currentState.copyWith(inProgress: true);
        final success = await attributeRequester.requestAttribute(
          currentState.enteredEmail,
          _selectedLanguage,
        );
        yield currentState.copyWith(
          inProgress: false,
          emailCouldNotBeSend: !success,
          showSuccessConfirmation: success,
        );
        if (success) {
          Future.delayed(showSuccessAlertDuration, () {
            dispatch(CloseSuccessAlert());
          });
        }
      }
    }

    if (event is CloseSuccessAlert) {
      yield currentState.copyWith(showSuccessConfirmation: false);
    }

    if (event is ClearEmail) {
      yield currentState.copyWith(enteredEmail: "");
    }
  }
}

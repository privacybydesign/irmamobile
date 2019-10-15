import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irmamobile/src/plugins/irma_mobile_bridge/events.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_bloc.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_event.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_state.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/choose_pin.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/confirm_pin.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/introduction.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/provide_email.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/welcome.dart';

class EnrollmentScreen extends StatelessWidget {
  static final routeName = "/enrollment";

  Widget build(BuildContext context) {
    EnrollmentBloc enrollmentBloc = EnrollmentBloc();
    return BlocProvider<EnrollmentBloc>.value(
        value: enrollmentBloc, child: ProvidedEnrollmentScreen(bloc: enrollmentBloc));
  }
}

class ProvidedEnrollmentScreen extends StatelessWidget {
  final EnrollmentBloc bloc;

  ProvidedEnrollmentScreen({this.bloc}) : super();

  submitPin(BuildContext context, String pin) {
    bloc.dispatch(PinSubmitted(pin: pin));
    Navigator.of(context).pushReplacementNamed(ConfirmPin.routeName);
  }

  submitConfirmationPin(pin) {
    bloc.dispatch(ConfirmationPinSubmitted(pin: pin));
  }

  submitEmail() {
    bloc.dispatch(EmailSubmitted());

    if (bloc.currentState.pinConfirmed && bloc.currentState.emailValid) {
      bloc.dispatch(EnrollEvent(email: bloc.currentState.email, pin: bloc.currentState.pin, language: 'nl'));
    }
  }

  changeEmail(email) {
    bloc.dispatch(EmailChanged(email: email));
  }

  @override
  Widget build(BuildContext context) {
    final buildListener = (BuildContext context, Widget child) {
      return BlocListener<EnrollmentBloc, EnrollmentState>(
        condition: (EnrollmentState previous, EnrollmentState current) {
          return current.pinConfirmed != previous.pinConfirmed;
        },
        listener: (BuildContext context, EnrollmentState state) {
          if (state.pinConfirmed == true) {
            Navigator.of(context).pushNamed(ProvideEmail.routeName);
          } else if (state.pinConfirmed == false) {
            Navigator.of(context).pushNamed(ChoosePin.routeName);
          }
        },
        child: child,
      );
    };

    return Navigator(
      initialRoute: Welcome.routeName,
      onGenerateRoute: (RouteSettings settings) {
        WidgetBuilder builder;
        switch (settings.name) {
          case Welcome.routeName:
            builder = (BuildContext c) => buildListener(c, Welcome());
            break;
          case Introduction.routeName:
            builder = (BuildContext c) => buildListener(c, Introduction());
            break;
          case ChoosePin.routeName:
            builder = (BuildContext c) => buildListener(c, ChoosePin(submitPin: submitPin));
            break;
          case ConfirmPin.routeName:
            builder = (BuildContext c) => buildListener(c, ConfirmPin(submitConfirmationPin: submitConfirmationPin));
            break;
          case ProvideEmail.routeName:
            builder =
                (BuildContext c) => buildListener(c, ProvideEmail(submitEmail: submitEmail, changeEmail: changeEmail));
            break;
          default:
            throw Exception('Invalid route: ${settings.name}');
        }

        return MaterialPageRoute(builder: builder, settings: settings);
      },
    );
  }
}

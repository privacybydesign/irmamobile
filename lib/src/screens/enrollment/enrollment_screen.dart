import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class ProvidedEnrollmentScreen extends StatefulWidget {
  final EnrollmentBloc bloc;

  ProvidedEnrollmentScreen({this.bloc}) : super();

  @override
  State<StatefulWidget> createState() => ProvidedEnrollmentScreenState(bloc: bloc);
}

class ProvidedEnrollmentScreenState extends State<ProvidedEnrollmentScreen> {
  final EnrollmentBloc bloc;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  ProvidedEnrollmentScreenState({this.bloc}) : super();

  Map<String, WidgetBuilder> _routeBuilders() {
    return {
      Welcome.routeName: (_) => Welcome(),
      Introduction.routeName: (_) => Introduction(),
      ChoosePin.routeName: (_) => ChoosePin(submitPin: submitPin, cancel: cancel),
      ConfirmPin.routeName: (_) => ConfirmPin(submitConfirmationPin: submitConfirmationPin, cancel: cancel),
      ProvideEmail.routeName: (_) => ProvideEmail(submitEmail: submitEmail, changeEmail: changeEmail, cancel: cancel),
    };
  }

  submitPin(BuildContext context, String pin) {
    bloc.dispatch(PinSubmitted(pin: pin));
    Navigator.of(context).pushNamed(ConfirmPin.routeName);
  }

  submitConfirmationPin(pin) {
    bloc.dispatch(ConfirmationPinSubmitted(pin: pin));
  }

  submitEmail() {
    bloc.dispatch(EmailSubmitted());
  }

  changeEmail(email) {
    bloc.dispatch(EmailChanged(email: email));
  }

  cancel() {
    bloc.dispatch(EnrollmentCanceled());
  }

  @override
  Widget build(BuildContext context) {
    final routeBuilders = _routeBuilders();

    return WillPopScope(
        onWillPop: () async {
          cancel();
          return !await navigatorKey.currentState.maybePop();
        },
        child: Navigator(
          key: navigatorKey,
          initialRoute: Welcome.routeName,
          onGenerateRoute: (RouteSettings settings) {
            if (!routeBuilders.containsKey(settings.name)) {
              throw Exception('Invalid route: ${settings.name}');
            }

            final child = routeBuilders[settings.name];
            final builder = (context) => BlocListener<EnrollmentBloc, EnrollmentState>(
                  condition: (EnrollmentState previous, EnrollmentState current) {
                    return current.pinConfirmed != previous.pinConfirmed || current.showPinValidation != previous.showPinValidation;
                  },
                  listener: (BuildContext context, EnrollmentState state) {
                    if (state.pinConfirmed == true) {
                      Navigator.of(context).pushReplacementNamed(ProvideEmail.routeName);
                    } else if (state.pinConfirmed == false && state.showPinValidation == true) {
                      Navigator.of(context).pushReplacementNamed(ChoosePin.routeName);
                    }
                  },
                  child: child(context),
                );

            return MaterialPageRoute(builder: builder, settings: settings);
          },
        ));
  }
}

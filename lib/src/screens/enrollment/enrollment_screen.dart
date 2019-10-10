import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_bloc.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_state.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/choose_pin.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/confirm_pin.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/introduction.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/provide_email.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/welcome.dart';

class EnrollmentScreen extends StatefulWidget {
  static final routeName = "/enrollment";

  @override
  State<StatefulWidget> createState() => EnrollmentScreenState();
}

class EnrollmentScreenState extends State<EnrollmentScreen> {
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final _routeBuilders = {
    Welcome.routeName: (_) => Welcome(),
    Introduction.routeName: (_) => Introduction(),
    ChoosePin.routeName: (_) => ChoosePin(),
    ConfirmPin.routeName: (_) => ConfirmPin(),
    ProvideEmail.routeName: (_) => ProvideEmail(),
  };

  @override
  Widget build(BuildContext context) {
    final buildListener = (BuildContext context, Widget child) {
      return BlocListener<EnrollmentBloc, EnrollmentState>(
        condition: (EnrollmentState previous, EnrollmentState current) {
          print(current.toString());
          return current.pinConfirmed != previous.pinConfirmed || current.emailValidated != previous.emailValidated;
        },
        listener: (BuildContext context, EnrollmentState state) {
          if (state.emailValidated == ValidationState.valid) {
            Navigator.of(context, rootNavigator: true).pushReplacementNamed('/');
          } else if (state.pinConfirmed == ValidationState.valid) {
            Navigator.of(context).pushReplacementNamed(ProvideEmail.routeName);
          } else if (state.pinConfirmed == ValidationState.invalid) {
            Navigator.of(context).pushReplacementNamed(ChoosePin.routeName);
          }
        },
        child: child,
      );
    };

    return BlocProvider<EnrollmentBloc>(
        builder: (context) => EnrollmentBloc(),
        child: WillPopScope(
            onWillPop: () async => !await navigatorKey.currentState.maybePop(),
            child: Navigator(
              key: navigatorKey,
              initialRoute: Welcome.routeName,
              onGenerateRoute: (RouteSettings settings) {
                return MaterialPageRoute(
                    builder: (BuildContext c) => buildListener(c, _routeBuilders[settings.name](c)),
                    settings: settings);
              },
            )));
  }
}

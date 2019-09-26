import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_bloc.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_state.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/choose_pin.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/confirm_pin.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/introduction.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/provide_email.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/welcome.dart';

class EnrollmentScreen extends StatelessWidget {
  static final routeName = "/enrollment";

  @override
  Widget build(BuildContext context) {
    final buildListener = (BuildContext context, Widget child) {
      return BlocListener<EnrollmentBloc, EnrollmentState>(
        condition: (EnrollmentState previous, EnrollmentState current) {
          return current.pinConfirmed != previous.pinConfirmed || current.emailValidated != previous.emailValidated;
        },
        listener: (BuildContext context, EnrollmentState state) {
          if (state.emailValidated == true) {
            // TODO navigate top the correct route
            Navigator.of(context).pushNamed(Welcome.routeName);
          } else if (state.pinConfirmed == true) {
            Navigator.of(context).pushNamed(ProvideEmail.routeName);
          } else if (state.pinConfirmed == false) {
            Navigator.of(context).pushNamed(ChoosePin.routeName);
          }
        },
        child: child,
      );
    };

    return BlocProvider<EnrollmentBloc>(
        builder: (context) => EnrollmentBloc(),
        child: Navigator(
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
                builder = (BuildContext c) => buildListener(c, ChoosePin());
                break;
              case ConfirmPin.routeName:
                builder = (BuildContext c) => buildListener(c, ConfirmPin());
                break;
              case ProvideEmail.routeName:
                builder = (BuildContext c) => buildListener(c, ProvideEmail());
                break;
              default:
                throw Exception('Invalid route: ${settings.name}');
            }

            return MaterialPageRoute(builder: builder, settings: settings);
          },
        ));
  }
}

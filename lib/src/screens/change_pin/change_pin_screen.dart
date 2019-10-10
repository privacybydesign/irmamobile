import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_bloc.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_state.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/choose_pin.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/confirm_pin.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/enter_pin.dart';

class ChangePinScreen extends StatelessWidget {
  static final routeName = "/change_pin";

  @override
  Widget build(BuildContext context) {
    final buildListener = (BuildContext context, Widget child) {
      return BlocListener<ChangePinBloc, ChangePinState>(
        condition: (ChangePinState previous, ChangePinState current) {
          print(current.toString());

          return current.newPinConfirmed != previous.newPinConfirmed ||
              current.oldPinVerified != previous.oldPinVerified;
        },
        listener: (BuildContext context, ChangePinState state) {
          if (state.oldPinVerified == true) {
            Navigator.of(context).pushNamed(ChoosePin.routeName);
          } else if (state.newPinConfirmed == false) {
            Navigator.of(context).pushNamed(ChoosePin.routeName);
          } else if (state.newPinConfirmed == true) {
            Navigator.of(context, rootNavigator: true).pushReplacementNamed('/');
          }
        },
        child: child,
      );
    };

    return BlocProvider<ChangePinBloc>(
        builder: (context) => ChangePinBloc(),
        child: Navigator(
          initialRoute: EnterPin.routeName,
          onGenerateRoute: (RouteSettings settings) {
            WidgetBuilder builder;
            switch (settings.name) {
              case EnterPin.routeName:
                builder = (BuildContext c) => buildListener(c, EnterPin());
                break;
              case ChoosePin.routeName:
                builder = (BuildContext c) => buildListener(c, ChoosePin());
                break;
              case ConfirmPin.routeName:
                builder = (BuildContext c) => buildListener(c, ConfirmPin());
                break;
              default:
                throw Exception('Invalid route: ${settings.name}');
            }

            return MaterialPageRoute(builder: builder, settings: settings);
          },
        ));
  }
}

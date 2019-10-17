import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_bloc.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_state.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/choose_pin.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/confirm_pin.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/enter_pin.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/success.dart';

class ChangePinScreen extends StatefulWidget {
  static final routeName = "/change_pin";

  @override
  State<StatefulWidget> createState() => ChangePinScreenState();
}

class ChangePinScreenState extends State<ChangePinScreen> {
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final _routeBuilders = {
    EnterPin.routeName: (_) => EnterPin(),
    ChoosePin.routeName: (_) => ChoosePin(),
    ConfirmPin.routeName: (_) => ConfirmPin(),
    Success.routeName: (_) => Success(),
  };

  @override
  Widget build(BuildContext context) {
    final buildListener = (BuildContext context, Widget child) {
      return BlocListener<ChangePinBloc, ChangePinState>(
        condition: (ChangePinState previous, ChangePinState current) {
          return current.newPinConfirmed != previous.newPinConfirmed ||
              current.oldPinVerified != previous.oldPinVerified;
        },
        listener: (BuildContext context, ChangePinState state) {
          if (state.newPinConfirmed == ValidationState.valid) {
            Navigator.of(context).pushNamed(Success.routeName);
          } else if (state.newPinConfirmed == ValidationState.invalid) {
            Navigator.of(context).pushNamed(ChoosePin.routeName);
          } else if (state.oldPinVerified == ValidationState.valid) {
            Navigator.of(context).pushNamed(ChoosePin.routeName);
          }
        },
        child: child,
      );
    };

    return BlocProvider<ChangePinBloc>(
        builder: (context) => ChangePinBloc(),
        child: WillPopScope(
            onWillPop: () async => !await navigatorKey.currentState.maybePop(),
            child: Navigator(
              key: navigatorKey,
              initialRoute: EnterPin.routeName,
              onGenerateRoute: (RouteSettings settings) {
                return MaterialPageRoute(
                    builder: (BuildContext c) => buildListener(c, _routeBuilders[settings.name](c)),
                    settings: settings);
              },
            )));
  }
}

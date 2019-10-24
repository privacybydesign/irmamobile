import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_bloc.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_event.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_state.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/choose_pin.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/confirm_pin.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/enter_pin.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/success.dart';

class ChangePinScreen extends StatelessWidget {
  static final routeName = "/change_pin";

  Widget build(BuildContext context) {
    ChangePinBloc changePinBloc = ChangePinBloc();
    return BlocProvider<ChangePinBloc>.value(value: changePinBloc, child: ProvidedChangePinScreen(bloc: changePinBloc));
  }
}

class ProvidedChangePinScreen extends StatefulWidget {
  final ChangePinBloc bloc;

  ProvidedChangePinScreen({this.bloc}) : super();

  @override
  State<StatefulWidget> createState() => ProvidedChangePinScreenState(bloc: bloc);
}

class ProvidedChangePinScreenState extends State<ProvidedChangePinScreen> {
  final ChangePinBloc bloc;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  ProvidedChangePinScreenState({this.bloc}) : super();

  Map<String, WidgetBuilder> _routeBuilders() {
    return {
      EnterPin.routeName: (_) => EnterPin(submitOldPin: submitOldPin, cancel: cancel),
      ChoosePin.routeName: (_) => ChoosePin(chooseNewPin: chooseNewPin, cancel: cancel),
      ConfirmPin.routeName: (_) => ConfirmPin(confirmNewPin: confirmNewPin, cancel: cancel),
      Success.routeName: (_) => Success(cancel: cancel),
    };
  }

  submitOldPin(String pin) {
    bloc.dispatch(OldPinEntered(pin: pin));
  }

  chooseNewPin(BuildContext context, String pin) {
    bloc.dispatch(NewPinChosen(pin: pin));
    Navigator.of(context).pushNamed(ConfirmPin.routeName);
  }

  confirmNewPin(String pin) {
    bloc.dispatch(NewPinConfirmed(pin: pin));
  }

  cancel() {
    bloc.dispatch(ChangePinCanceled());
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
          initialRoute: EnterPin.routeName,
          onGenerateRoute: (RouteSettings settings) {
            if (!routeBuilders.containsKey(settings.name)) {
              throw Exception('Invalid route: ${settings.name}');
            }

            final child = routeBuilders[settings.name];
            final builder = (context) => BlocListener<ChangePinBloc, ChangePinState>(
                  condition: (ChangePinState previous, ChangePinState current) {
                    return current.newPinConfirmed != previous.newPinConfirmed ||
                        current.oldPinVerified != previous.oldPinVerified ||
                        current.retry != previous.retry;
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
                  child: child(context),
                );

            return MaterialPageRoute(builder: builder, settings: settings);
          },
        ));
  }
}

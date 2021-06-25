import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_bloc.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_event.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_state.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/choose_pin.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/confirm_error_dialog.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/confirm_pin.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/enter_pin.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/success.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/updating_pin.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/valdating_pin.dart';
import 'package:irmamobile/src/screens/error/error_screen.dart';
import 'package:irmamobile/src/screens/error/session_error_screen.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';
import 'package:irmamobile/src/util/hero_controller.dart';
import 'package:irmamobile/src/widgets/pin_common/pin_wrong_attempts.dart';

class ChangePinScreen extends StatelessWidget {
  static const routeName = "/change_pin";

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChangePinBloc>(
        create: (_) => ChangePinBloc(),
        child: BlocBuilder<ChangePinBloc, ChangePinState>(builder: (context, _) {
          final bloc = BlocProvider.of<ChangePinBloc>(context);
          return ProvidedChangePinScreen(bloc: bloc);
        }));
  }
}

class ProvidedChangePinScreen extends StatefulWidget {
  final ChangePinBloc bloc;

  const ProvidedChangePinScreen({this.bloc}) : super();

  @override
  State<StatefulWidget> createState() => ProvidedChangePinScreenState(bloc: bloc);
}

class ProvidedChangePinScreenState extends State<ProvidedChangePinScreen> {
  final IrmaRepository _repo = IrmaRepository.get();
  final ChangePinBloc bloc;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final FocusNode currentPinFocusNode = FocusNode();
  final FocusNode newPinFocusNode = FocusNode();

  ProvidedChangePinScreenState({this.bloc}) : super();

  Map<String, WidgetBuilder> _routeBuilders() {
    return {
      EnterPin.routeName: (_) =>
          EnterPin(pinFocusNode: currentPinFocusNode, submitOldPin: submitOldPin, cancel: cancel),
      ValidatingPin.routeName: (_) => ValidatingPin(cancel: cancel),
      ChoosePin.routeName: (_) => ChoosePin(
          pinFocusNode: newPinFocusNode, chooseNewPin: chooseNewPin, toggleLongPin: toggleLongPin, cancel: cancel),
      ConfirmPin.routeName: (_) => ConfirmPin(confirmNewPin: confirmNewPin, cancel: () => {}),
      UpdatingPin.routeName: (_) => UpdatingPin(cancel: cancel),
      Success.routeName: (_) => Success(cancel: cancel),
    };
  }

  void submitOldPin(String pin) {
    bloc.add(OldPinEntered(pin: pin));
  }

  void toggleLongPin() {
    bloc.add(ToggleLongPin());
  }

  void chooseNewPin(BuildContext context, String pin) {
    bloc.add(NewPinChosen(pin: pin));
    navigatorKey.currentState.pushNamed(ConfirmPin.routeName);
  }

  void confirmNewPin(String pin) {
    bloc.add(NewPinConfirmed(pin: pin));
  }

  void cancel() {
    bloc.add(ChangePinCanceled());
  }

  @override
  Widget build(BuildContext context) {
    final routeBuilders = _routeBuilders();

    return BlocListener<ChangePinBloc, ChangePinState>(
        condition: (ChangePinState previous, ChangePinState current) {
          return current.newPinConfirmed != previous.newPinConfirmed ||
              current.oldPinVerified != previous.oldPinVerified ||
              current.validatingPin != previous.validatingPin ||
              current.attemptsRemaining != previous.attemptsRemaining;
        },
        listener: (BuildContext context, ChangePinState state) {
          if (state.newPinConfirmed == ValidationState.valid) {
            navigatorKey.currentState.pushNamedAndRemoveUntil(Success.routeName, (_) => false);
          } else if (state.newPinConfirmed == ValidationState.invalid) {
            navigatorKey.currentState.pop();
            // show error overlay
            showDialog(
              context: context,
              builder: (BuildContext context) => ConfirmErrorDialog(onClose: () async {
                // close the overlay
                Navigator.of(context).pop();
                newPinFocusNode.requestFocus();
              }),
            );
          } else if (state.newPinConfirmed == ValidationState.error) {
            if (state.error != null) {
              navigatorKey.currentState.pushReplacement(MaterialPageRoute(
                builder: (context) => SessionErrorScreen(
                  error: state.error,
                  onTapClose: () => navigatorKey.currentState.pop(),
                ),
              ));
            } else {
              navigatorKey.currentState.pushReplacement(MaterialPageRoute(
                builder: (context) => GeneralErrorScreen(
                  errorText: state.errorMessage,
                  onTapClose: () => navigatorKey.currentState.pop(),
                ),
              ));
            }
          } else if (state.oldPinVerified == ValidationState.valid) {
            navigatorKey.currentState.pushReplacementNamed(ChoosePin.routeName);
          } else if (state.oldPinVerified == ValidationState.invalid) {
            // go back
            navigatorKey.currentState.pop();
            // and indicate mistake to user
            if (state.attemptsRemaining != 0) {
              showDialog(
                context: context,
                builder: (context) => PinWrongAttemptsDialog(attemptsRemaining: state.attemptsRemaining),
              );
            } else {
              Navigator.of(context, rootNavigator: true).popUntil(ModalRoute.withName(WalletScreen.routeName));
              _repo.lock(unblockTime: state.blockedUntil);
            }
          } else if (state.oldPinVerified == ValidationState.error) {
            navigatorKey.currentState.pushReplacement(MaterialPageRoute(
              builder: (context) => SessionErrorScreen(
                error: state.error,
                onTapClose: () {
                  navigatorKey.currentState.pop();
                },
              ),
            ));
          } else if (state.updatingPin == true) {
            navigatorKey.currentState.pushNamed(UpdatingPin.routeName);
          } else if (state.validatingPin == true) {
            navigatorKey.currentState.pushNamed(ValidatingPin.routeName);
          }
        },
        child: HeroControllerScope(
          controller: createHeroController(),
          child: Navigator(
            key: navigatorKey,
            initialRoute: EnterPin.routeName,
            onGenerateRoute: (RouteSettings settings) {
              if (!routeBuilders.containsKey(settings.name)) {
                throw Exception('Invalid route: ${settings.name}');
              }
              final child = routeBuilders[settings.name];

              return MaterialPageRoute(builder: child, settings: settings);
            },
          ),
        ));
  }
}

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
import 'package:irmamobile/src/screens/change_pin/widgets/updating_pin.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/valdating_pin.dart';
import 'package:irmamobile/src/screens/error/error_screen.dart';
import 'package:irmamobile/src/screens/error/session_error_screen.dart';
import 'package:irmamobile/src/screens/home/home_screen.dart';
import 'package:irmamobile/src/screens/settings/settings_screen.dart';
import 'package:irmamobile/src/util/hero_controller.dart';
import 'package:irmamobile/src/widgets/pin_common/pin_wrong_attempts.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_repository_provider.dart';
import '../../widgets/translated_text.dart';
import '../pin/yivi_pin_screen.dart';

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

  const ProvidedChangePinScreen({required this.bloc}) : super();

  @override
  State<StatefulWidget> createState() => ProvidedChangePinScreenState();
}

class ProvidedChangePinScreenState extends State<ProvidedChangePinScreen> {
  final IrmaRepository _repo = IrmaRepository.get();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Map<String, WidgetBuilder> _routeBuilders() {
    return {
      EnterPin.routeName: (_) => EnterPin(submitOldPin: submitOldPin, cancel: cancel),
      ValidatingPin.routeName: (_) => ValidatingPin(cancel: cancel),
      ChoosePin.routeName: (_) => ChoosePin(chooseNewPin: chooseNewPin, cancel: cancel),
      ConfirmPin.routeName: (_) => ConfirmPin(confirmNewPin: confirmNewPin, cancel: returnToChoosePin),
      UpdatingPin.routeName: (_) => UpdatingPin(cancel: cancel),
    };
  }

  void submitOldPin(String pin) {
    widget.bloc.add(OldPinEntered(pin: pin));
  }

  void chooseNewPin(BuildContext context, String pin) {
    widget.bloc.add(NewPinChosen(pin: pin));
    navigatorKey.currentState?.pushNamed(ConfirmPin.routeName, arguments: pin.length > shortPinSize);
  }

  void returnToChoosePin() => navigatorKey.currentState?.pushReplacementNamed(ChoosePin.routeName);

  void confirmNewPin(String pin) {
    widget.bloc.add(NewPinConfirmed(pin: pin));
  }

  void cancel() {
    // Return to SettingsScreen
    Navigator.maybePop(context).then(
      (_) => Navigator.of(context).popUntil(
        (route) => route.settings.name == SettingsScreen.routeName,
      ),
    );
  }

  void _handleResetPinSuccess(BuildContext context, ChangePinState state) {
    final prefs = IrmaRepositoryProvider.of(context).preferences;
    final theme = IrmaTheme.of(context);
    prefs.setLongPin(state.longPin);
    cancel();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TranslatedText(
          'change_pin.toast',
          style: theme.themeData.textTheme.caption!.copyWith(color: theme.light),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.themeData.colorScheme.secondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeBuilders = _routeBuilders();

    return BlocListener<ChangePinBloc, ChangePinState>(
        listenWhen: (ChangePinState previous, ChangePinState current) {
          return current.newPinConfirmed != previous.newPinConfirmed ||
              current.oldPinVerified != previous.oldPinVerified ||
              current.validatingPin != previous.validatingPin ||
              current.attemptsRemaining != previous.attemptsRemaining;
        },
        listener: (BuildContext context, ChangePinState state) {
          if (state.newPinConfirmed == ValidationState.valid) {
            _handleResetPinSuccess(context, state);
          } else if (state.newPinConfirmed == ValidationState.invalid) {
            navigatorKey.currentState?.pop();
            // show error overlay
            showDialog(
              context: context,
              builder: (BuildContext context) => ConfirmErrorDialog(onClose: () async {
                // close the overlay
                Navigator.of(context).pop();
              }),
            );
          } else if (state.newPinConfirmed == ValidationState.error) {
            if (state.error != null) {
              navigatorKey.currentState?.pushReplacement(MaterialPageRoute(
                builder: (context) => SessionErrorScreen(
                  error: state.error,
                  onTapClose: () => navigatorKey.currentState?.pop(),
                ),
              ));
            } else {
              navigatorKey.currentState?.pushReplacement(MaterialPageRoute(
                builder: (context) => ErrorScreen(
                  details: state.errorMessage,
                  onTapClose: () => navigatorKey.currentState?.pop(),
                ),
              ));
            }
          } else if (state.oldPinVerified == ValidationState.valid) {
            navigatorKey.currentState?.pushReplacementNamed(ChoosePin.routeName);
          } else if (state.oldPinVerified == ValidationState.invalid) {
            // go back
            navigatorKey.currentState?.pop();
            // and indicate mistake to user
            if (state.attemptsRemaining != 0) {
              showDialog(
                context: context,
                builder: (context) => PinWrongAttemptsDialog(attemptsRemaining: state.attemptsRemaining),
              );
            } else {
              Navigator.of(context, rootNavigator: true).popUntil(ModalRoute.withName(HomeScreen.routeName));
              _repo.lock(unblockTime: state.blockedUntil);
            }
          } else if (state.oldPinVerified == ValidationState.error) {
            navigatorKey.currentState?.pushReplacement(MaterialPageRoute(
              builder: (context) => SessionErrorScreen(
                error: state.error,
                onTapClose: () {
                  navigatorKey.currentState?.pop();
                },
              ),
            ));
          } else if (state.updatingPin == true) {
            navigatorKey.currentState?.pushNamed(UpdatingPin.routeName);
          } else if (state.validatingPin == true) {
            navigatorKey.currentState?.pushNamed(ValidatingPin.routeName);
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

              // only assert in debug mode
              assert(child != null);

              return MaterialPageRoute(builder: child!, settings: settings);
            },
          ),
        ));
  }
}

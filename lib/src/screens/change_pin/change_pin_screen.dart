import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/irma_repository.dart';
import '../../theme/theme.dart';
import '../../util/hero_controller.dart';
import '../../widgets/irma_repository_provider.dart';
import '../../widgets/pin_common/pin_wrong_attempts.dart';
import '../../widgets/translated_text.dart';
import '../change_pin/models/change_pin_bloc.dart';
import '../change_pin/models/change_pin_event.dart';
import '../change_pin/models/change_pin_state.dart';
import '../change_pin/widgets/choose_pin.dart';
import '../change_pin/widgets/confirm_error_dialog.dart';
import '../change_pin/widgets/confirm_pin.dart';
import '../change_pin/widgets/enter_pin.dart';
import '../change_pin/widgets/updating_pin.dart';
import '../change_pin/widgets/validating_pin.dart';
import '../error/error_screen.dart';
import '../error/session_error_screen.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';

class ChangePinScreen extends StatelessWidget {
  static const routeName = "/change_pin";

  @override
  Widget build(BuildContext context) {
    final IrmaRepository repo = IrmaRepositoryProvider.of(context);
    return BlocProvider<ChangePinBloc>(
        create: (_) => ChangePinBloc(repo),
        child: BlocBuilder<ChangePinBloc, ChangePinState>(builder: (context, _) {
          final bloc = BlocProvider.of<ChangePinBloc>(context);
          return ProvidedChangePinScreen(bloc: bloc, repo: repo);
        }));
  }
}

class ProvidedChangePinScreen extends StatefulWidget {
  final ChangePinBloc bloc;
  final IrmaRepository repo;

  const ProvidedChangePinScreen({required this.bloc, required this.repo}) : super();

  @override
  State<StatefulWidget> createState() => ProvidedChangePinScreenState();
}

class ProvidedChangePinScreenState extends State<ProvidedChangePinScreen> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  get theme => IrmaTheme.of(context);
  final newPin = ValueNotifier<String>('');

  Map<String, WidgetBuilder> _routeBuilders() {
    return {
      EnterPin.routeName: (_) => EnterPin(submitOldPin: _submitOldPin, cancel: _gotoSettings),
      ValidatingPin.routeName: (_) => ValidatingPin(cancel: _gotoSettings),
      ChoosePin.routeName: (_) => ChoosePin(
            chooseNewPin: _chooseNewPin,
            cancel: _gotoSettings,
            newPinNotifier: newPin,
          ),
      ConfirmPin.routeName: (_) => ConfirmPin(
            confirmNewPin: _confirmNewPin,
            cancel: _gotoSettings,
            returnToChoosePin: _returnToChoosePin,
            onPinMismatch: _handlePinMismatch,
            newPinNotifier: newPin,
          ),
      UpdatingPin.routeName: (_) => UpdatingPin(cancel: _gotoSettings),
    };
  }

  void _returnToChoosePin() {
    navigatorKey.currentState?.popUntil(
      (route) => route.settings.name == ChoosePin.routeName,
    );
  }

  void _submitOldPin(String pin) {
    widget.bloc.add(OldPinEntered(pin: pin));
  }

  void _chooseNewPin(String pin) {
    widget.bloc.add(NewPinChosen(pin: pin));
    navigatorKey.currentState?.pushNamed(ConfirmPin.routeName, arguments: pin);
  }

  void _confirmNewPin(String pin) {
    widget.bloc.add(NewPinConfirmed(pin: pin));
  }

  void _gotoSettings() {
    // Return to SettingsScreen
    Navigator.maybePop(context).then(
      (_) => Navigator.of(context).popUntil(
        (route) => route.settings.name == SettingsScreen.routeName,
      ),
    );
  }

  void _handlePinMismatch() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => ConfirmErrorDialog(),
    );
  }

  void _onSuccessShowFloatingSnackbar() => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TranslatedText(
            'change_pin.toast',
            style: theme.themeData.textTheme.caption!.copyWith(color: theme.light),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: theme.themeData.colorScheme.secondary,
        ),
      );

  void _handleResetPinSuccess(ChangePinState state) {
    widget.repo.preferences.setLongPin(state.longPin);
    _gotoSettings();
    _onSuccessShowFloatingSnackbar();
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
            _handleResetPinSuccess(state);
          } else if (state.newPinConfirmed == ValidationState.invalid) {
            // wrong confirmation pin entered
            navigatorKey.currentState?.pop();
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
            // old pin verified, proceed to new pin screen
            navigatorKey.currentState?.pushReplacementNamed(ChoosePin.routeName);
          } else if (state.oldPinVerified == ValidationState.invalid) {
            // go back
            navigatorKey.currentState?.pop();
            // and indicate mistake to user
            if (state.attemptsRemaining != 0) {
              showDialog(
                context: context,
                builder: (context) => PinWrongAttemptsDialog(
                  attemptsRemaining: state.attemptsRemaining,
                  onClose: Navigator.of(context).pop,
                ),
              );
            } else {
              Navigator.of(context, rootNavigator: true).popUntil(ModalRoute.withName(HomeScreen.routeName));
              widget.repo.lock(unblockTime: state.blockedUntil);
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

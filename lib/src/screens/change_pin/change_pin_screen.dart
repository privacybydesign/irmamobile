import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/irma_repository.dart';
import '../../models/session.dart';
import '../../providers/irma_repository_provider.dart';
import '../../theme/theme.dart';
import '../../util/navigation.dart';
import '../../widgets/pin_common/pin_wrong_attempts.dart';
import '../../widgets/translated_text.dart';
import '../change_pin/models/change_pin_bloc.dart';
import '../change_pin/models/change_pin_event.dart';
import '../change_pin/models/change_pin_state.dart';
import '../change_pin/widgets/confirm_pin.dart';
import '../change_pin/widgets/enter_pin.dart';
import '../enrollment/choose_pin/choose_pin_screen.dart';
import '../enrollment/confirm_pin/widgets/pin_confirmation_failed_dialog.dart';
import '../error/session_error_screen.dart';
import 'models/old_pin_verification_state.dart';
import 'models/validation_state.dart';
import 'models/verify_old_pin_bloc.dart';

class ChangePinScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final IrmaRepository repo = IrmaRepositoryProvider.of(context);
    final changePinBloc = ChangePinBloc(repo);
    final verifyOldPinBloc = VerifyOldPinBloc(repo);
    return ProvidedChangePinScreen(
      verifyOldPinBloc: verifyOldPinBloc,
      changePinBloc: changePinBloc,
      repo: repo,
    );
  }
}

class ProvidedChangePinScreen extends StatefulWidget {
  final ChangePinBloc changePinBloc;
  final VerifyOldPinBloc verifyOldPinBloc;
  final IrmaRepository repo;

  const ProvidedChangePinScreen({
    required this.repo,
    required this.changePinBloc,
    required this.verifyOldPinBloc,
  }) : super();

  @override
  State<StatefulWidget> createState() => ProvidedChangePinScreenState();
}

class ProvidedChangePinScreenState extends State<ProvidedChangePinScreen> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  get theme => IrmaTheme.of(context);
  final newPin = ValueNotifier<String>('');

  Map<String, WidgetBuilder> _routeBuilders() {
    return {
      EnterPin.routeName: (_) => EnterPin(submitOldPin: _submitOldPin, cancel: context.goSettingsScreen),
      ChoosePinScreen.routeName: (_) => ChoosePinScreen(
            onChoosePin: _chooseNewPin,
            onPrevious: context.goSettingsScreen,
            newPinNotifier: newPin,
          ),
      ConfirmPin.routeName: (_) => ConfirmPin(
            confirmNewPin: _confirmNewPin,
            cancel: context.goSettingsScreen,
            returnToChoosePin: _returnToChoosePin,
            onPinMismatch: _handlePinMismatch,
            newPinNotifier: newPin,
          ),
    };
  }

  void _returnToChoosePin() {
    navigatorKey.currentState?.popUntil(
      (route) => route.settings.name == ChoosePinScreen.routeName,
    );
  }

  void _submitOldPin(String pin) {
    widget.verifyOldPinBloc.add(pin);
    widget.changePinBloc.add(PinEvent(pin, PinEventType.oldPinEntered));
  }

  void _chooseNewPin(String pin) {
    widget.changePinBloc.add(PinEvent(pin, PinEventType.newPinChosen));
    navigatorKey.currentState?.pushNamed(ConfirmPin.routeName, arguments: pin);
  }

  void _confirmNewPin(String pin) {
    widget.changePinBloc.add(PinEvent(pin, PinEventType.newPinConfirmed));
  }

  void _handlePinMismatch() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => PinConfirmationFailedDialog(
        onPressed: () {
          Navigator.pop(context); // pop dialog
          navigatorKey.currentState
            ?..popUntil(
              (route) => route.settings.name == ChoosePinScreen.routeName,
            )
            ..pushReplacementNamed(
              ChoosePinScreen.routeName,
            );
        },
      ),
    );
  }

  void _onSuccessShowFloatingSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TranslatedText(
          'change_pin.toast',
          style: theme.themeData.textTheme.bodySmall!.copyWith(color: theme.light),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.themeData.colorScheme.secondary,
      ),
    );
  }

  void _handleResetPinSuccess() {
    context.goSettingsScreen();
    _onSuccessShowFloatingSnackbar();
  }

  void _handleBadPinAttempts(int attemptsRemaining, DateTime? blockedUntil) {
    // go back
    navigatorKey.currentState?.pop();
    // and indicate mistake to user
    if (attemptsRemaining > 0) {
      showDialog(
        context: context,
        builder: (context) => PinWrongAttemptsDialog(
          attemptsRemaining: attemptsRemaining,
          onClose: Navigator.of(context).pop,
        ),
      );
    } else {
      context.goHomeScreenWithoutTransition();
      widget.repo.lock(unblockTime: blockedUntil);
    }
  }

  void _handleException(SessionError? e) {
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        builder: (context) => SessionErrorScreen(
          error: e,
          onTapClose: () {
            navigatorKey.currentState?.pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeBuilders = _routeBuilders();

    return MultiBlocListener(
      listeners: [
        BlocListener<ChangePinBloc, ChangePinState>(
          bloc: widget.changePinBloc,
          listener: (BuildContext context, ChangePinState state) {
            switch (state.newPinConfirmed) {
              case ValidationState.valid:
                _handleResetPinSuccess();
                break;
              case ValidationState.error:
                _handleException(state.error);
                break;
              default:
                break;
            }
          },
        ),
        BlocListener<VerifyOldPinBloc, OldPinVerificationState>(
          bloc: widget.verifyOldPinBloc,
          listener: (BuildContext context, OldPinVerificationState state) {
            switch (state.validationState) {
              case ValidationState.valid:
                HapticFeedback.mediumImpact();
                // old pin verified, proceed to new pin screen
                navigatorKey.currentState?.pushReplacementNamed(ChoosePinScreen.routeName);
                break;
              case ValidationState.invalid:
                HapticFeedback.heavyImpact();
                assert(state.attemptsRemaining != null);
                _handleBadPinAttempts(state.attemptsRemaining!, state.blockedUntil);
                navigatorKey.currentState?.pushNamed(EnterPin.routeName);
                break;
              case ValidationState.error:
                HapticFeedback.heavyImpact();
                _handleException(state.error);
                break;
              case ValidationState.initial: // for completeness
                break;
            }
          },
        ),
      ],
      child: HeroControllerScope(
        controller: MaterialApp.createMaterialHeroController(),
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
      ),
    );
  }
}

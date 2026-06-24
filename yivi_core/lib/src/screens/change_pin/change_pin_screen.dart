import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../models/session.dart";
import "../../providers/irma_repository_provider.dart";
import "../../util/navigation.dart";
import "../../widgets/pin_common/pin_wrong_attempts.dart";
import "../../widgets/translated_text.dart";
import "../change_pin/widgets/confirm_pin.dart";
import "../change_pin/widgets/enter_pin.dart";
import "../enrollment/choose_pin/choose_pin_screen.dart";
import "../enrollment/confirm_pin/widgets/pin_confirmation_failed_dialog.dart";
import "../error/session_error_screen.dart";
import "models/change_pin_state.dart";
import "models/old_pin_verification_state.dart";
import "models/validation_state.dart";
import "providers/change_pin_providers.dart";

class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final newPin = ValueNotifier<String>("");

  Map<String, WidgetBuilder> _routeBuilders() {
    return {
      EnterPin.routeName: (_) => EnterPin(
        submitOldPin: _submitOldPin,
        cancel: context.goSettingsScreen,
      ),
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
    ref.read(changePinProvider.notifier).setOldPin(pin);
    ref.read(verifyOldPinProvider.notifier).verify(pin);
  }

  void _chooseNewPin(String pin) {
    ref.read(changePinProvider.notifier).setNewPin(pin);
    navigatorKey.currentState?.pushNamed(ConfirmPin.routeName, arguments: pin);
  }

  void _confirmNewPin(String pin) {
    ref.read(changePinProvider.notifier).confirmNewPin();
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
            ..pushReplacementNamed(ChoosePinScreen.routeName);
        },
      ),
    );
  }

  void _onSuccessShowFloatingSnackbar() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: TranslatedText("change_pin.toast")));
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
      ref.read(irmaRepositoryProvider).lock(unblockTime: blockedUntil);
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
    ref.listen<ChangePinState>(changePinProvider, (_, state) {
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
    });

    ref.listen<OldPinVerificationState>(verifyOldPinProvider, (_, state) {
      switch (state.validationState) {
        case ValidationState.valid:
          HapticFeedback.mediumImpact();
          // old pin verified, proceed to new pin screen
          navigatorKey.currentState?.pushReplacementNamed(
            ChoosePinScreen.routeName,
          );
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
    });

    final routeBuilders = _routeBuilders();

    return HeroControllerScope(
      controller: MaterialApp.createMaterialHeroController(),
      child: Navigator(
        key: navigatorKey,
        initialRoute: EnterPin.routeName,
        onGenerateRoute: (RouteSettings settings) {
          if (!routeBuilders.containsKey(settings.name)) {
            throw Exception("Invalid route: ${settings.name}");
          }
          final child = routeBuilders[settings.name];

          // only assert in debug mode
          assert(child != null);

          return MaterialPageRoute(builder: child!, settings: settings);
        },
      ),
    );
  }
}

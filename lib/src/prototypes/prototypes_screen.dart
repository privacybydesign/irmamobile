import 'package:flutter/material.dart';

import '../screens/error/blocked_screen.dart';
import '../screens/error/error_screen.dart';
import '../screens/error/no_internet_screen.dart';
import '../screens/loading/loading_screen.dart';
import '../screens/pin/yivi_pin_screen.dart';
import '../screens/required_update/required_update_screen.dart';
import '../screens/rooted_warning/rooted_warning_screen.dart';
import '../screens/session/disclosure/widgets/disclosure_permission_introduction_screen.dart';
import '../screens/session/widgets/arrow_back_screen.dart';
import '../screens/session/widgets/disclosure_feedback_screen.dart';
import '../screens/session/widgets/pairing_required.dart';
import '../screens/splash_screen/splash_screen.dart';
import '../widgets/irma_error_scaffold_body.dart';
import 'prototype_pin_screen.dart';

class PrototypesScreen extends StatelessWidget {
  static const routeName = '/';
  final pinBloc5 = EnterPinStateBloc(5);
  final pinBloc16 = EnterPinStateBloc(16);

  Widget _buildTile(
    BuildContext context,
    String title,
    Widget screen,
  ) =>
      ListTile(
        title: Text(title),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => screen,
          ),
        ),
      );

  Widget _toggleSetPinSize({
    required BuildContext context,
    required bool isShort,
    required String instructionKey,
  }) {
    final size = isShort ? 5 : 16;
    final pinBloc = isShort ? pinBloc5 : pinBloc16;

    return SecurePinScreenTest(
      maxPinSize: size,
      onTogglePinSize: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => _toggleSetPinSize(
              context: context,
              isShort: !isShort,
              instructionKey: instructionKey,
            ),
          ),
        );
      },
      instructionKey: instructionKey,
      pinBloc: pinBloc,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Screens')),
      body: ListView(
        children: [
          _buildTile(
            context,
            'Basic pin input, exactly 5 digits',
            PinScreenTest(
              maxPinSize: 5,
              pinBloc: pinBloc5,
            ),
          ),
          _buildTile(
            context,
            'Basic pin input, >5 digits, at most 16',
            PinScreenTest(
              maxPinSize: 16,
              pinBloc: pinBloc16,
            ),
          ),
          _buildTile(
            context,
            'Onboarding pin, pin size = 5',
            _toggleSetPinSize(
              context: context,
              isShort: true,
              instructionKey: 'enrollment.choose_pin.title',
            ),
          ),
          _buildTile(
            context,
            'Onboarding pin, pin size > 5',
            _toggleSetPinSize(
              context: context,
              isShort: false,
              instructionKey: 'enrollment.choose_pin.title',
            ),
          ),
          _buildTile(
            context,
            'Reset pin, pin size = 5',
            _toggleSetPinSize(
              context: context,
              isShort: true,
              instructionKey: 'change_pin.enter_pin.title',
            ),
          ),
          _buildTile(
            context,
            'Reset pin, pin size > 5',
            _toggleSetPinSize(
              context: context,
              isShort: false,
              instructionKey: 'change_pin.enter_pin.title',
            ),
          ),
          _buildTile(
            context,
            'Arrow back',
            const ArrowBack(
              success: true,
              amountIssued: 1,
            ),
          ),
          _buildTile(
            context,
            'Update required',
            RequiredUpdateScreen(),
          ),
          _buildTile(
            context,
            'Root warning',
            const RootedWarningScreen(),
          ),
          _buildTile(
            context,
            'No internet',
            NoInternetScreen(
              onTapClose: Navigator.of(context).pop,
              onTapRetry: () {},
            ),
          ),
          _buildTile(
            context,
            'Blocked',
            BlockedScreen(),
          ),
          _buildTile(
            context,
            'General error',
            ErrorScreen(
              onTapClose: Navigator.of(context).pop,
            ),
          ),
          _buildTile(
            context,
            'Error: pairing rejected',
            ErrorScreen(
              onTapClose: Navigator.of(context).pop,
              type: ErrorType.pairingRejected,
            ),
          ),
          _buildTile(
            context,
            'Pairing required',
            PairingRequired(
              pairingCode: '4567',
              onDismiss: Navigator.of(context).pop,
            ),
          ),
          _buildTile(
            context,
            'Error: session unknown / unexpected request',
            ErrorScreen(
              onTapClose: Navigator.of(context).pop,
              type: ErrorType.expired,
            ),
          ),
          _buildTile(
            context,
            'Disclosure feedback - success',
            DisclosureFeedbackScreen(
              feedbackType: DisclosureFeedbackType.success,
              otherParty: 'successful party',
              popToWallet: Navigator.pop,
            ),
          ),
          _buildTile(
            context,
            'Disclosure feedback - canceled',
            DisclosureFeedbackScreen(
              feedbackType: DisclosureFeedbackType.canceled,
              otherParty: 'canceled party',
              popToWallet: Navigator.pop,
            ),
          ),
          _buildTile(
            context,
            'Disclosure feedback - not satisfiable',
            DisclosureFeedbackScreen(
              feedbackType: DisclosureFeedbackType.notSatisfiable,
              otherParty: 'unsatisfied party',
              popToWallet: Navigator.pop,
            ),
          ),
          _buildTile(
            context,
            'Splash screen',
            const SplashScreen(),
          ),
          _buildTile(
            context,
            'Loading screen',
            LoadingScreen(),
          ),
          _buildTile(
            context,
            'Disclosure permission introduction',
            DisclosurePermissionIntroductionScreen(
              onEvent: (_) {},
            ),
          ),
        ],
      ),
    );
  }
}

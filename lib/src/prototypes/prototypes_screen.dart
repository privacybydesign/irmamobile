import 'package:flutter/material.dart';
import 'package:irmamobile/src/screens/error/blocked_screen.dart';
import 'package:irmamobile/src/screens/error/error_screen.dart';
import 'package:irmamobile/src/screens/error/no_internet_screen.dart';
import 'package:irmamobile/src/screens/session/widgets/disclosure_feedback_screen.dart';

import '../screens/required_update/required_update_screen.dart';
import '../screens/rooted_warning/rooted_warning_screen.dart';
import '../screens/session/widgets/arrow_back_screen.dart';

class PrototypesScreen extends StatelessWidget {
  static const routeName = "/";

  Widget _buildTile(BuildContext context, String title, Widget w) => ListTile(
        title: Text(title),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => w,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ListTile(
            title: const Text('Arrow back screen'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ArrowBack(
                  amountIssued: 0,
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Required update screen'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RequiredUpdateScreen(),
              ),
            ),
          ),
          ListTile(
            title: const Text('Rooted warning screen'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RootedWarningScreen(),
              ),
            ),
          ),
          _buildTile(
              context,
              'No internet screen',
              NoInternetScreen(
                onTapClose: () => Navigator.pop(context),
                onTapRetry: () {},
              )),
          _buildTile(context, 'Blocked screen', BlockedScreen()),
          _buildTile(
              context,
              'General error screen',
              ErrorScreen(
                onTapClose: () => Navigator.pop(context),
              )),
          _buildTile(
              context,
              'Error screen: pairing rejected',
              ErrorScreen(
                onTapClose: () => Navigator.pop(context),
                type: ErrorType.pairingRejected,
              )),
          _buildTile(
              context,
              'Error screen: session unknown / unexpected request',
              ErrorScreen(
                onTapClose: () => Navigator.pop(context),
                type: ErrorType.expired,
              )),
          _buildTile(
              context,
              'Disclosure feedback screen - success',
              DisclosureFeedbackScreen(
                feedbackType: DisclosureFeedbackType.success,
                otherParty: 'party time!',
                popToWallet: (c) => Navigator.pop(context),
              )),
          _buildTile(
              context,
              'Disclosure feedback screen - canceled',
              DisclosureFeedbackScreen(
                feedbackType: DisclosureFeedbackType.canceled,
                otherParty: 'no party time :(',
                popToWallet: (c) => c, //Navigator.pop(context),
              )),
          _buildTile(
              context,
              'Disclosure feedback screen - not satisfiable',
              DisclosureFeedbackScreen(
                feedbackType: DisclosureFeedbackType.notSatisfiable,
                otherParty: "I can't get no satisfaction :(",
                popToWallet: (c) => c, //Navigator.pop(context),
              )),
        ],
      ),
    );
  }
}

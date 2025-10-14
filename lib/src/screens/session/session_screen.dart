import 'package:flutter/material.dart';

import '../../models/protocol.dart';
import '../../util/navigation.dart';
import 'widgets/irma_session_screen.dart';

class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key, required this.arguments});
  final SessionRouteParams arguments;

  @override
  Widget build(BuildContext context) {
    if (arguments.protocol == Protocol.openid4vci) {
      return Placeholder();
    }
    return IrmaSessionScreen(arguments: arguments);
  }
}

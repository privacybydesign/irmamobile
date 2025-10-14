import 'package:flutter/material.dart';

import '../../models/protocol.dart';
import '../../util/navigation.dart';
import 'widgets/irma_session_screen.dart';
import 'widgets/openid4vci_session_screen.dart';

class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key, required this.params});
  final SessionRouteParams params;

  @override
  Widget build(BuildContext context) {
    return switch (params.protocol) {
      Protocol.openid4vci => OpenID4VciSessionScreen(params: params),
      Protocol.irma || Protocol.openid4vp => IrmaSessionScreen(params: params),
    };
  }
}

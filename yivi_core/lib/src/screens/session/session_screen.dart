import "package:flutter/material.dart";

import "../../util/navigation.dart";
import "widgets/schemaless_session_screen.dart";

class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key, required this.params});
  final SessionRouteParams params;

  @override
  Widget build(BuildContext context) {
    return SchemalessSessionScreen(sessionId: params.sessionID);
  }
}

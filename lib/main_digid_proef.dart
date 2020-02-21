import 'package:flutter/material.dart';
import 'package:irmamobile/src/data/irma_client_bridge.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/widgets/nudge_state.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  IrmaRepository(client: IrmaClientBridge());

  runApp(const Nudge(
    nudgeState: NudgeState.digidProef,
    child: App(),
  ));
}

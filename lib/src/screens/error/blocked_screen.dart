import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/clear_all_data_event.dart';
import 'package:irmamobile/src/screens/error/blocked.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';

class BlockedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Disable popping of this screen, as popping this is unwanted
        // (only way forward is and should be a reset, giving accidental access
        // to the wallet of a blocked account is unreasonable, even though credentials
        // can no longer be used)
        return false;
      },
      child: Scaffold(
        appBar: IrmaAppBar(
          title: Text(
            FlutterI18n.translate(
              context,
              'error.blocked_title',
            ),
          ),
          // ignore: avoid_redundant_argument_values
          noLeading: kReleaseMode,
          leadingAction: () {
            if (kDebugMode) {
              Navigator.pop(context);
            }
          },
        ),
        body: Blocked(),
        bottomNavigationBar: IrmaBottomBar(
          primaryButtonLabel: FlutterI18n.translate(context, 'error.button_reset'),
          onPrimaryPressed: () {
            IrmaRepository.get().bridgedDispatch(
              ClearAllDataEvent(),
            );
          },
        ),
      ),
    );
  }
}

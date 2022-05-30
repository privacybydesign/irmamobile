import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

import '../../widgets/irma_bottom_bar.dart';
import '../../widgets/irma_info_scaffold_body.dart';

class RootedWarningScreen extends StatelessWidget {
  final VoidCallback? onAcceptRiskButtonPressed;

  const RootedWarningScreen({
    this.onAcceptRiskButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kDebugMode
          ? IrmaAppBar(
              title: const Text(
                "This won't appear on the release build",
              ),
              // ignore: avoid_redundant_argument_values
              noLeading: kReleaseMode,
              leadingAction: () {
                if (kDebugMode) {
                  Navigator.pop(context);
                }
              },
            )
          : null,
      body: const IrmaInfoScaffoldBody(
        icon: Icons.gpp_bad_outlined,
        iconColor: Colors.red,
        titleKey: 'rooted_warning.title',
        bodyKey: 'rooted_warning.explanation',
      ),
      bottomNavigationBar: IrmaBottomBar(
        key: const Key('warning_screen_accept_button'),
        primaryButtonLabel: FlutterI18n.translate(context, 'rooted_warning.accept_risk'),
        onPrimaryPressed: () => onAcceptRiskButtonPressed?.call(),
      ),
    );
  }
}

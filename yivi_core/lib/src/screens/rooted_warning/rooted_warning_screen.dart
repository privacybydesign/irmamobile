import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

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
      body: const IrmaInfoScaffoldBody(
        imagePath: 'assets/error/insecure_device_illustration.svg',
        titleTranslationKey: 'rooted_warning.title',
        bodyTranslationKey: 'rooted_warning.explanation',
      ),
      bottomNavigationBar: IrmaBottomBar(
        key: const Key('warning_screen_accept_button'),
        primaryButtonLabel: FlutterI18n.translate(context, 'rooted_warning.accept_risk'),
        onPrimaryPressed: () => onAcceptRiskButtonPressed?.call(),
      ),
    );
  }
}

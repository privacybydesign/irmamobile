import 'package:flutter/material.dart';
import 'package:irmamobile/src/widgets/issuer_verifier_header.dart';

import '../../../widgets/irma_app_bar.dart';

class WizardScaffold extends StatelessWidget {
  final Image image;
  final String header;
  final Color backgroundColor;
  final Color textColor;
  final Widget bottomBar;
  final Widget body;
  final void Function() onBack;
  final GlobalKey scrollviewKey;
  final ScrollController controller;

  const WizardScaffold({
    required this.image,
    required this.header,
    required this.backgroundColor,
    required this.textColor,
    required this.bottomBar,
    required this.body,
    required this.scrollviewKey,
    required this.controller,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        titleTranslationKey: 'issue_wizard.add_cards',
        leadingAction: onBack,
      ),
      bottomNavigationBar: bottomBar,
      body: SingleChildScrollView(
        controller: controller,
        key: scrollviewKey,
        child: Column(
          children: [
            IssuerVerifierHeader(
              title: header,
              image: image,
            ),
            body,
          ],
        ),
      ),
    );
  }
}

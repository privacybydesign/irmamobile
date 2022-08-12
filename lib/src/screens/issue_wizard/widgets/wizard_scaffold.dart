import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../widgets/irma_app_bar.dart';
import '../../../widgets/issuer_verifier_header.dart';

class WizardScaffold extends StatelessWidget {
  final Image image;
  final String header;
  final Widget bottomBar;
  final Widget body;
  final void Function() onBack;
  final GlobalKey scrollviewKey;
  final ScrollController controller;

  const WizardScaffold({
    required this.image,
    required this.header,
    required this.bottomBar,
    required this.body,
    required this.scrollviewKey,
    required this.controller,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
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
            Container(
              color: theme.light,
              padding: EdgeInsets.all(theme.defaultSpacing),
              child: IssuerVerifierHeader(
                title: header,
                image: image,
              ),
            ),
            body,
          ],
        ),
      ),
    );
  }
}

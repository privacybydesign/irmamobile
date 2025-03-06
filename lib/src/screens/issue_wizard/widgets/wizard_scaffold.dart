import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../widgets/irma_app_bar.dart';
import '../../../widgets/requestor_header.dart';

class WizardScaffold extends StatelessWidget {
  final Image image;
  final String header;
  final Widget bottomBar;
  final Widget body;
  final void Function() onBack;
  final GlobalKey scrollviewKey;
  final ScrollController controller;
  final Color? headerBackgroundColor;
  final Color? headerTextColor;

  const WizardScaffold({
    required this.image,
    required this.header,
    required this.bottomBar,
    required this.body,
    required this.scrollviewKey,
    required this.controller,
    required this.onBack,
    this.headerBackgroundColor,
    this.headerTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundSecondary,
      appBar: IrmaAppBar(
        titleTranslationKey: 'issue_wizard.add_cards',
        leadingAction: onBack,
      ),
      bottomNavigationBar: bottomBar,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        controller: controller,
        key: scrollviewKey,
        child: SafeArea(
          child: Column(
            children: [
              IssueWizardRequestorHeader(
                title: header,
                image: image,
                textColor: headerTextColor,
                backgroundColor: headerBackgroundColor,
              ),
              SizedBox(height: theme.smallSpacing),
              body,
            ],
          ),
        ),
      ),
    );
  }
}

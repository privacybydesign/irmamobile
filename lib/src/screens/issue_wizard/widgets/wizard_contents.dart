import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/issue_wizard/issue_wizard.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../models/issue_wizard.dart';
import '../../../screens/issue_wizard/widgets/wizard_info.dart';
import '../../../theme/theme.dart';
import '../../../util/color_from_code.dart';
import '../../../widgets/irma_bottom_bar.dart';
import '../../../widgets/irma_markdown.dart';
import '../../../widgets/irma_progress_indicator.dart';
import 'wizard_card_list.dart';
import 'wizard_scaffold.dart';

class IssueWizardContents extends StatelessWidget {
  final GlobalKey scrollviewKey;
  final ScrollController controller;
  final IssueWizardEvent wizard;
  final Image logo;
  final void Function() onBack;
  final void Function(BuildContext context, IssueWizardEvent wizard) onNext;
  final void Function(VisibilityInfo visibility, IssueWizardEvent wizard) onVisibilityChanged;

  const IssueWizardContents({
    required this.scrollviewKey,
    required this.controller,
    required this.wizard,
    required this.logo,
    required this.onBack,
    required this.onNext,
    required this.onVisibilityChanged,
  });

  Widget _buildWizard(BuildContext context, IssueWizardEvent wizard) {
    final lang = FlutterI18n.currentLocale(context)?.languageCode ?? customWizardDefaultLanguage;
    final contents = wizard.wizardContents
        .map((item) => WizardCardItem(
              header: item.header.translate(lang),
              text: item.text.translate(lang),
              completed: item.completed,
            ))
        .toList();

    final intro = wizard.wizardData.intro;
    final theme = IrmaTheme.of(context);
    return VisibilityDetector(
      key: const Key('wizard-key'),
      onVisibilityChanged: (v) => onVisibilityChanged(v, wizard),
      child: Container(
        padding: EdgeInsets.only(left: theme.defaultSpacing, right: theme.defaultSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (intro.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: theme.defaultSpacing),
                child: IrmaMarkdown(intro.translate(lang)),
              ),
            WizardCardList(data: contents, completed: wizard.completed),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)?.languageCode ?? customWizardDefaultLanguage;
    final activeItem = wizard.activeItem;
    final buttonLabel = wizard.completed
        ? FlutterI18n.translate(context, "issue_wizard.done")
        : activeItem?.label.translate(lang,
            fallback: FlutterI18n.translate(
              context,
              "issue_wizard.add_credential",
              translationParams: {"credential": activeItem.header.translate(lang)},
            ));
    final wizardContentSize = wizard.wizardContents.length;
    final indicator = <Widget>[
      const SizedBox(
        height: 4,
      ),
      Padding(
        padding: EdgeInsets.only(left: theme.defaultSpacing, right: theme.defaultSpacing),
        child: IrmaProgressIndicator(
          step: wizard.completed ? wizard.wizardContents.length : wizard.activeItemIndex,
          stepCount: wizardContentSize,
        ),
      ),
      const SizedBox(
        height: 32,
      )
    ];
    return WizardScaffold(
      scrollviewKey: scrollviewKey,
      controller: controller,
      header: wizard.wizardData.title.translate(lang),
      logo: logo,
      backgroundColor: colorFromCode(wizard.wizardData.color) ?? IssueWizardScreen.defaultBackgroundColor,
      textColor: colorFromCode(wizard.wizardData.textColor) ?? IssueWizardScreen.defaultTextColor,
      onBack: onBack,
      bottomBar: IrmaBottomBar(
        primaryButtonLabel: buttonLabel,
        onPrimaryPressed: () => onNext(context, wizard),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (wizardContentSize > 1) ...indicator,
          _buildWizard(context, wizard),
        ],
      ),
    );
  }
}

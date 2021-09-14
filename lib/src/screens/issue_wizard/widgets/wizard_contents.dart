// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/issue_wizard.dart';
import 'package:irmamobile/src/screens/issue_wizard/widgets/logo_banner_header.dart';
import 'package:irmamobile/src/screens/issue_wizard/widgets/progressing_list.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/color_from_code.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:irmamobile/src/widgets/irma_markdown.dart';
import 'package:visibility_detector/visibility_detector.dart';

class IssueWizardContents extends StatelessWidget {
  final GlobalKey scrollviewKey;
  final ScrollController controller;
  final IssueWizardEvent wizard;
  final Image logo;
  final Widget bottomBar;
  final void Function() onBack;
  final void Function(BuildContext context, IssueWizardEvent wizard) onNext;
  final void Function(VisibilityInfo visibility, IssueWizardEvent wizard) onVisibilityChanged;

  const IssueWizardContents({
    this.scrollviewKey,
    this.controller,
    this.wizard,
    this.logo,
    this.bottomBar,
    this.onBack,
    this.onNext,
    this.onVisibilityChanged,
  });

  Widget _buildWizard(BuildContext context, IssueWizardEvent wizard) {
    final lang = FlutterI18n.currentLocale(context).languageCode;
    final contents = wizard.wizardContents
        .map((item) => ProgressingListItem(
              header: item.header.translate(lang),
              text: item.text.translate(lang),
              completed: item.completed ?? false,
            ))
        .toList();

    final intro = wizard.wizardData.intro;
    final theme = IrmaTheme.of(context);
    return VisibilityDetector(
      key: const Key('wizard-key'),
      onVisibilityChanged: (v) => onVisibilityChanged(v, wizard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (intro.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.defaultSpacing),
              child: IrmaMarkdown(intro.translate(lang)),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              theme.defaultSpacing,
              theme.mediumSpacing,
              theme.defaultSpacing,
              theme.smallSpacing,
            ),
            child: ProgressingList(data: contents, completed: wizard.completed),
          ),
          if (wizard.showSuccess && wizard.completed)
            Padding(
              padding: EdgeInsets.fromLTRB(theme.defaultSpacing, 0, theme.defaultSpacing, theme.smallSpacing),
              child: Text(
                wizard.wizardData.successHeader.translate(lang),
                style: Theme.of(context).textTheme.headline3,
              ),
            ),
          if (wizard.showSuccess && wizard.completed)
            Padding(
              padding: EdgeInsets.fromLTRB(theme.defaultSpacing, 0, theme.defaultSpacing, theme.smallSpacing),
              child: IrmaMarkdown(wizard.wizardData.successText.translate(lang)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = FlutterI18n.currentLocale(context).languageCode;
    final buttonLabel = wizard.completed
        ? FlutterI18n.translate(context, "issue_wizard.done")
        : wizard.activeItem.label.translate(lang,
            fallback: FlutterI18n.translate(
              context,
              "issue_wizard.add_credential",
              translationParams: {"credential": wizard.activeItem.header.translate(lang)},
            ));

    return LogoBannerHeader(
      scrollviewKey: scrollviewKey,
      controller: controller,
      header: wizard.wizardData.title.translate(lang),
      logo: logo,
      backgroundColor: colorFromCode(wizard.wizardData.color),
      textColor: wizard.wizardData.color == null ? null : colorFromCode(wizard.wizardData.textColor),
      onBack: onBack,
      bottomBar: IrmaBottomBar(
        primaryButtonLabel: buttonLabel,
        onPrimaryPressed: () => onNext(context, wizard),
      ),
      child: _buildWizard(context, wizard),
    );
  }
}

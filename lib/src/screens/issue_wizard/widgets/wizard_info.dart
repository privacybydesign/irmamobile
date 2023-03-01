import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/issue_wizard.dart';
import '../../../theme/theme.dart';
import '../../../util/color_from_code.dart';
import '../../../widgets/collapsible.dart';
import '../../../widgets/irma_bottom_bar.dart';
import '../../../widgets/irma_markdown.dart';
import 'wizard_scaffold.dart';

class IssueWizardInfo extends StatelessWidget {
  final GlobalKey scrollviewKey;
  final ScrollController controller;
  final IssueWizard wizardData;
  final Image logo;
  final void Function() onNext;
  final void Function() onBack;

  const IssueWizardInfo({
    required this.scrollviewKey,
    required this.controller,
    required this.wizardData,
    required this.logo,
    required this.onNext,
    required this.onBack,
  });

  Widget _buildIntro(BuildContext context, String lang, IssueWizard wizardData) {
    final theme = IrmaTheme.of(context);

    final _collapsableKeys = List<GlobalKey>.generate(wizardData.faq.length, (int index) => GlobalKey());
    final items = wizardData.faq
        .asMap()
        .entries
        .map(
          (q) => Collapsible(
            key: _collapsableKeys[q.key],
            header: q.value.question.translate(lang),
            parentScrollController: controller,
            content: SizedBox(
              width: double.infinity,
              child: IrmaMarkdown(
                q.value.answer.translate(lang),
              ),
            ),
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IrmaMarkdown(wizardData.info.translate(lang)),
        SizedBox(height: theme.mediumSpacing),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, i) => items.elementAt(i),
          separatorBuilder: (_, i) => SizedBox(height: theme.smallSpacing),
          itemCount: items.length,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    return WizardScaffold(
      scrollviewKey: scrollviewKey,
      controller: controller,
      header: wizardData.title.translate(lang),
      image: logo,
      onBack: onBack,
      headerBackgroundColor: colorFromCode(wizardData.color),
      headerTextColor: wizardData.color == null ? null : colorFromCode(wizardData.textColor),
      bottomBar: IrmaBottomBar(
        primaryButtonLabel: 'issue_wizard.add',
        onPrimaryPressed: onNext,
        secondaryButtonLabel: 'issue_wizard.back',
        onSecondaryPressed: onBack,
        alignment: IrmaBottomBarAlignment.horizontal,
      ),
      body: _buildIntro(context, lang, wizardData),
    );
  }
}

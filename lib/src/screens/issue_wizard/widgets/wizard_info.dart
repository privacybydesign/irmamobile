import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/issue_wizard.dart';
import '../../../theme/theme.dart';
import '../../../widgets/collapsible.dart';
import '../../../widgets/irma_bottom_bar.dart';
import '../../../widgets/irma_markdown.dart';
import '../issue_wizard.dart';
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

  Widget _buildCollapsible(BuildContext context, GlobalKey key, String header, String body) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
      child: Collapsible(
        header: header,
        parentScrollController: controller,
        content: SizedBox(width: double.infinity, child: IrmaMarkdown(body)),
        key: key,
      ),
    );
  }

  Widget _buildIntro(BuildContext context, String lang, IssueWizard wizardData) {
    final _collapsableKeys = List<GlobalKey>.generate(wizardData.faq.length, (int index) => GlobalKey());
    final items = wizardData.faq
        .asMap()
        .entries
        .map(
          (q) => _buildCollapsible(
            context,
            _collapsableKeys[q.key],
            q.value.question.translate(lang),
            q.value.answer.translate(lang),
          ),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            IrmaTheme.of(context).defaultSpacing,
            0,
            IrmaTheme.of(context).defaultSpacing,
            IrmaTheme.of(context).defaultSpacing,
          ),
          child: IrmaMarkdown(wizardData.info.translate(lang)),
        ),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, i) => items.elementAt(i),
          separatorBuilder: (_, i) => const SizedBox(height: 8),
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
      backgroundColor: IssueWizardScreen.defaultBackgroundColor,
      textColor: IssueWizardScreen.defaultTextColor,
      onBack: onBack,
      bottomBar: IrmaBottomBar(
        primaryButtonLabel: FlutterI18n.translate(context, 'issue_wizard.add'),
        onPrimaryPressed: onNext,
        secondaryButtonLabel: FlutterI18n.translate(context, 'issue_wizard.back'),
        onSecondaryPressed: onBack,
        alignment: IrmaBottomBarAlignment.horizontal,
      ),
      body: _buildIntro(context, lang, wizardData),
    );
  }
}

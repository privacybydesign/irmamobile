import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/issue_wizard.dart';
import '../../../screens/issue_wizard/widgets/logo_banner_header.dart';
import '../../../theme/theme.dart';
import '../../../util/color_from_code.dart';
import '../../../widgets/collapsible.dart';
import '../../../widgets/irma_bottom_bar.dart';
import '../../../widgets/irma_markdown.dart';

const customWizardDefaultLanguage = 'en'; // TODO or NL?

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

  Widget _buildIntro(BuildContext context, IssueWizard wizardData) {
    final _collapsableKeys = List<GlobalKey>.generate(wizardData.faq.length, (int index) => GlobalKey());
    final lang = FlutterI18n.currentLocale(context)?.languageCode ?? customWizardDefaultLanguage;
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
      children: <Widget>[
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
    return LogoBannerHeader(
      scrollviewKey: scrollviewKey,
      controller: controller,
      header:
          wizardData.title.translate(FlutterI18n.currentLocale(context)?.languageCode ?? customWizardDefaultLanguage),
      logo: logo,
      backgroundColor: colorFromCode(wizardData.color),
      textColor: colorFromCode(wizardData.color ?? wizardData.textColor),
      onBack: onBack,
      bottomBar: IrmaBottomBar(
        primaryButtonLabel: FlutterI18n.translate(context, "issue_wizard.add"),
        onPrimaryPressed: onNext,
        secondaryButtonLabel: FlutterI18n.translate(context, "issue_wizard.back"),
        onSecondaryPressed: onBack,
      ),
      child: _buildIntro(context, wizardData),
    );
  }
}

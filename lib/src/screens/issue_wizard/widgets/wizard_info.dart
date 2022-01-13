// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/issue_wizard.dart';
import 'package:irmamobile/src/screens/issue_wizard/widgets/logo_banner_header.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/collapsible_helper.dart';
import 'package:irmamobile/src/util/color_from_code.dart';
import 'package:irmamobile/src/widgets/collapsible.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:irmamobile/src/widgets/irma_markdown.dart';

class IssueWizardInfo extends StatelessWidget {
  final GlobalKey scrollviewKey;
  final ScrollController controller;
  final IssueWizard wizardData;
  final Image logo;
  final void Function() onNext;
  final void Function() onBack;

  const IssueWizardInfo({
    this.scrollviewKey,
    this.controller,
    this.wizardData,
    this.logo,
    this.onNext,
    this.onBack,
  });

  Widget _buildCollapsible(BuildContext context, GlobalKey key, String header, String body) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
      child: Collapsible(
        header: header,
        onExpansionChanged: (v) => {if (v) jumpToCollapsable(controller, scrollviewKey, key)},
        content: SizedBox(width: double.infinity, child: IrmaMarkdown(body)),
        key: key,
      ),
    );
  }

  Widget _buildIntro(BuildContext context, IssueWizard wizardData) {
    final _collapsableKeys = List<GlobalKey>.generate(wizardData.faq.length, (int index) => GlobalKey());
    final lang = FlutterI18n.currentLocale(context).languageCode;
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
        ...wizardData.faq.asMap().entries.map(
              (q) => _buildCollapsible(
                context,
                _collapsableKeys[q.key],
                q.value.question.translate(lang),
                q.value.answer.translate(lang),
              ),
            )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LogoBannerHeader(
      scrollviewKey: scrollviewKey,
      controller: controller,
      header: wizardData.title.translate(FlutterI18n.currentLocale(context).languageCode),
      logo: logo,
      backgroundColor: colorFromCode(wizardData.color),
      textColor: wizardData.color == null ? null : colorFromCode(wizardData.textColor),
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

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../models/issue_wizard.dart';
import '../../../theme/theme.dart';
import '../../../util/color_from_code.dart';
import '../../../widgets/irma_bottom_bar.dart';
import '../../../widgets/irma_card.dart';
import '../../../widgets/irma_markdown.dart';
import '../../../widgets/irma_stepper.dart';
import '../../../widgets/session_progress_indicator.dart';
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

  Widget _buildWizard(BuildContext context, String lang, IssueWizardEvent wizard) {
    final intro = wizard.wizardData.intro;
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final firstIncomplete = wizard.wizardContents.indexWhere((el) => !el.completed);
    return VisibilityDetector(
      key: const Key('wizard_key'),
      onVisibilityChanged: (v) => onVisibilityChanged(v, wizard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (intro.isNotEmpty) ...[
            IrmaMarkdown(intro.translate(lang)),
            SizedBox(height: theme.defaultSpacing),
          ],
          IrmaStepper(
            currentIndex: wizard.activeItemIndex >= 0 ? wizard.activeItemIndex : null,
            children: wizard.wizardContents
                .mapIndexed(
                  (i, item) => IrmaCard(
                    style: i == firstIncomplete ? IrmaCardStyle.highlighted : IrmaCardStyle.normal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.header.translate(lang),
                          style: theme.textTheme.bodyLarge,
                        ),
                        Text(
                          item.text.translate(lang),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final activeItem = wizard.activeItem;
    final buttonLabel = wizard.completed
        ? FlutterI18n.translate(context, 'issue_wizard.done')
        : activeItem?.label.translate(lang,
            fallback: FlutterI18n.translate(
              context,
              'issue_wizard.add_credential',
              translationParams: {
                'credential': activeItem.header.translate(lang),
              },
            ));
    final wizardContentSize = wizard.wizardContents.length;

    return WizardScaffold(
      scrollviewKey: scrollviewKey,
      controller: controller,
      header: wizard.wizardData.title.translate(lang),
      image: logo,
      onBack: onBack,
      headerBackgroundColor: colorFromCode(wizard.wizardData.color),
      headerTextColor: wizard.wizardData.color == null ? null : colorFromCode(wizard.wizardData.textColor),
      bottomBar: IrmaBottomBar(
        primaryButtonLabel: buttonLabel,
        onPrimaryPressed: () => onNext(context, wizard),
        alignment: IrmaBottomBarAlignment.horizontal,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (wizardContentSize > 1 && wizard.activeItemIndex > -1)
            SessionProgressIndicator(
              step: wizard.activeItemIndex + 1,
              stepCount: wizardContentSize,
            ),
          SizedBox(height: theme.smallSpacing),
          _buildWizard(context, lang, wizard),
        ],
      ),
    );
  }
}

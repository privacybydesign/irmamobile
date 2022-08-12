import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/issue_wizard.dart';
import '../../../theme/theme.dart';
import '../../../widgets/irma_card.dart';
import '../../../widgets/irma_stepper.dart';

class WizardCardStepper extends StatelessWidget {
  final List<IssueWizardItem> data;
  final bool completed;

  const WizardCardStepper({
    Key? key,
    required this.data,
    this.completed = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activeItemIndex = data.indexWhere((item) => !item.completed);
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    final contents = data
        .map(
          (item) => IrmaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.header.translate(lang), style: theme.textTheme.bodyText1),
                Text(item.text.translate(lang), style: theme.textTheme.bodyText2),
              ],
            ),
          ),
        )
        .toList();

    return IrmaStepper(children: contents, currentIndex: activeItemIndex >= 0 ? activeItemIndex : null);
  }
}

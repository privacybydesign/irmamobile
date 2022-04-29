import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/translated_text.dart';
import '../bloc/disclosure_permission_event.dart';
import '../bloc/disclosure_permission_state.dart';
import 'disclosure_issue_wizard_step.dart';

class DisclosureIssueWizardChoices extends StatelessWidget {
  final DisclosurePermissionIssueWizardChoices state;
  final Function(DisclosurePermissionBlocEvent) onEvent;

  const DisclosureIssueWizardChoices({
    required this.state,
    required this.onEvent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TranslatedText(
          'disclosure_permission.issue_wizard_choice.choose_data',
          style: theme.themeData.textTheme.headline3,
        ),
        SizedBox(height: theme.defaultSpacing),
        for (var i = 0; i < state.issueWizardChoices.length; i++) ...[
          DisclosureIssueWizardStep(
            state: state,
            onEvent: onEvent,
            stepIndex: i,
          ),
          //If this is not the last item add a divider
          if (i != state.issueWizardChoices.length - 1)
            const Center(
                child: TranslatedText(
              'disclosure_permission.issue_wizard_choice.and',
              textAlign: TextAlign.center,
            ))
        ]
      ],
    );
  }
}

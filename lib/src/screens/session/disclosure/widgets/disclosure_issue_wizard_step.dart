import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/credential_card/irma_credentials_card.dart';
import '../bloc/disclosure_permission_event.dart';
import '../bloc/disclosure_permission_state.dart';

class DisclosureIssueWizardStep extends StatelessWidget {
  final DisclosurePermissionIssueWizardChoices state;
  final Function(DisclosurePermissionBlocEvent) onEvent;
  final int stepIndex;

  const DisclosureIssueWizardStep({required this.state, required this.stepIndex, required this.onEvent});

  @override
  Widget build(BuildContext context) {
    final step = state.issueWizardChoices[stepIndex];

    return Column(
      children: [
        for (var i = 0; i < step.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: IrmaTheme.of(context).tinySpacing),
            child: IrmaCredentialsCard(
              mode: IrmaCredentialsCardMode.issuanceChoice,
              selected: state.issueWizardChoiceIndices[stepIndex] == i,
              attributesByCredential: {
                for (var cred in step[i]) cred: [],
              },
              onTap: () => onEvent(
                DisclosurePermissionIssueWizardChoiceUpdated(
                  stepIndex: stepIndex,
                  choiceIndex: i,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

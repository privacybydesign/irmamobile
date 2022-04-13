import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/credential_card/irma_credentials_card.dart';
import '../bloc/disclosure_permission_bloc.dart';
import '../bloc/disclosure_permission_event.dart';
import '../bloc/disclosure_permission_state.dart';

class IssueWizardStep extends StatelessWidget {
  final DisclosurePermissionBloc bloc;
  final int stepIndex;

  const IssueWizardStep({
    required this.bloc,
    required this.stepIndex,
  });

  @override
  Widget build(BuildContext context) {
    final state = bloc.state as DisclosurePermissionIssueWizardChoices;
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
              onTap: () => bloc.add(
                DisclosurePermissionIssueWizardChoiceUpdated(
                  stepIndex: stepIndex,
                  choiceIndex: i,
                ),
              ),
            ),
          )
      ],
    );
  }
}

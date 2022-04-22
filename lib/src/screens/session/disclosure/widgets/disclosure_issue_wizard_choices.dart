import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/irma_bottom_bar.dart';
import '../../../../widgets/translated_text.dart';
import '../bloc/disclosure_permission_bloc.dart';
import '../bloc/disclosure_permission_event.dart';
import '../bloc/disclosure_permission_state.dart';
import 'disclosure_issue_wizard_step.dart';

class DisclosureIssueWizardChoices extends StatelessWidget {
  final DisclosurePermissionBloc bloc;

  const DisclosureIssueWizardChoices(this.bloc);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final state = bloc.state as DisclosurePermissionIssueWizardChoices;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.all(theme.defaultSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranslatedText(
                'disclosure_permission.issue_wizard_choice.choose_data',
                style: theme.themeData.textTheme.headline3,
              ),
              SizedBox(height: theme.defaultSpacing),
              for (var i = 0; i < state.issueWizardChoices.length; i++) ...[
                DisclosureIssueWizardStep(
                  bloc: bloc,
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
          ),
        ),
        Align(
            alignment: Alignment.bottomCenter,
            child: IrmaBottomBar(
                primaryButtonLabel: 'disclosure_permission.next',
                onPrimaryPressed: () => bloc.add(DisclosurePermissionNextPressed())))
      ],
    );
  }
}

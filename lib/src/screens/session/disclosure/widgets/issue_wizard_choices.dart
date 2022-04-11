import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/irma_bottom_bar.dart';
import '../../../../widgets/translated_text.dart';
import '../bloc/disclosure_permission_bloc.dart';
import '../bloc/disclosure_permission_event.dart';
import '../bloc/disclosure_permission_state.dart';
import 'issue_wizard_choice.dart';

class IssueWizardChoices extends StatelessWidget {
  final DisclosurePermissionBloc bloc;

  const IssueWizardChoices(this.bloc);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final state = bloc.state as DisclosurePermissionIssueWizardChoices;
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.all(theme.defaultSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranslatedText(
                'disclosure.disclosure_permission.issue_wizard_choice.choose_data',
                style: theme.themeData.textTheme.headline3,
              ),
              SizedBox(height: theme.defaultSpacing),
              for (var disCon in state.issueWizardChoices)
                IssueWizardChoice(
                  bloc: bloc,
                  disCon: disCon,
                )
            ],
          ),
        ),
        // Align(
        //     alignment: Alignment.bottomCenter,
        //     child: IrmaBottomBar(
        //         primaryButtonLabel: 'disclosure.disclosure_permission.next',
        //         onPrimaryPressed: () =>
        //         bloc.add(  DisclosurePermissionIssueWizardChoiceUpdated({required this.stepIndex, required this.choiceIndex});)
        //         //bloc.add(DisclosurePermissionNextPressed())
        //         ))
      ],
    );
  }
}

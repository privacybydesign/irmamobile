import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../models/attributes.dart';
import '../../../../models/session.dart';
import '../../../../theme/theme.dart';
import '../../../../widgets/irma_bottom_bar.dart';
import '../../../../widgets/irma_progress_indicator.dart';
import '../../../../widgets/irma_quote.dart';
import '../../../../widgets/irma_repository_provider.dart';
import '../../../../widgets/translated_text.dart';
import '../../../activity/widgets/issuer_verifier_header.dart';
import '../../widgets/session_scaffold.dart';
import '../bloc/disclosure_permission_event.dart';
import '../bloc/disclosure_permission_state.dart';
import '../models/disclosure_credential.dart';
import 'disclosure_issue_wizard_stepper.dart';

class DisclosurePermissionIssueWizardScreen extends StatelessWidget {
  final RequestorInfo requestor;
  final DisclosurePermissionIssueWizard state;
  final Function(DisclosurePermissionBlocEvent) onEvent;

  const DisclosurePermissionIssueWizardScreen({
    required this.requestor,
    required this.state,
    required this.onEvent,
  });

  void _onButtonPressed(BuildContext context) {
    if (!state.isCompleted) {
      // Get the con that needs to be fetched
      Con<DisclosureCredential> con;
      // If this is a choice get the selected con
      if (state.currentDiscon!.value.length > 1) {
        con = state.getSelectedCon(state.currentDiscon!.key)!;
      } else {
        // Else get the first con.
        con = state.currentDiscon!.value.first;
      }
      //TODO Check credentials length, not con length.
      //If multiple credentials need to be fetched, start sub issue wizard
      if (con.length > 1) {
        //TODO Start sub issue wizard.
      } else {
        IrmaRepositoryProvider.of(context).openIssueURL(
          context,
          con.first.credentialType.fullId,
        );
      }
    } else {
      // Go to next step in disclosure permission flow.
      onEvent(DisclosurePermissionNextPressed());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return SessionScaffold(
      appBarTitle: 'disclosure_permission.issue_wizard.title',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IssuerVerifierHeader(title: requestor.name.translate(lang)),
            IrmaProgressIndicator(
              step: state.currentStepIndex + 1,
              stepCount: state.plannedSteps.length,
            ),
            SizedBox(height: theme.defaultSpacing),
            IrmaQuote(
              richQuote: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${FlutterI18n.translate(context, 'ui.step')} ${state.currentStepIndex + 1}: ',
                      style: theme.themeData.textTheme.caption!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: FlutterI18n.translate(
                        context,
                        'disclosure_permission.issue_wizard.explanation',
                      ),
                      style: theme.themeData.textTheme.caption,
                    ),
                  ],
                ),
              ),
              color: theme.lightBeige,
            ),
            SizedBox(height: theme.defaultSpacing),
            TranslatedText(
              'disclosure_permission.issue_wizard.add_data',
              style: theme.themeData.textTheme.headline3,
            ),
            SizedBox(height: theme.defaultSpacing),
            DisclosureIssueWizardStepper(
              candidates: state.candidates,
              currentCandidate: state.currentDiscon!,
              selectedConIndices: state.selectedConIndices,
              onChoiceUpdatedEvent: (int conIndex) => onEvent(
                DisclosurePermissionChoiceUpdated(
                  conIndex: conIndex,
                ),
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel:
            state.isCompleted ? 'disclosure_permission.issue_wizard.next' : 'disclosure_permission.issue_wizard.fetch',
        onPrimaryPressed: () => _onButtonPressed(context),
      ),
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../models/session.dart';
import '../../../../theme/theme.dart';
import '../../../../widgets/irma_bottom_bar.dart';
import '../../../../widgets/irma_progress_indicator.dart';
import '../../../../widgets/irma_quote.dart';
import '../../../../widgets/translated_text.dart';
import '../../../activity/widgets/issuer_verifier_header.dart';
import '../../widgets/session_scaffold.dart';
import '../bloc/disclosure_permission_event.dart';
import '../bloc/disclosure_permission_state.dart';
import 'disclosure_discon_stepper.dart';

class DisclosurePermissionIssueWizardScreen extends StatelessWidget {
  final RequestorInfo requestor;
  final DisclosurePermissionIssueWizard state;
  final Function(DisclosurePermissionBlocEvent) onEvent;

  const DisclosurePermissionIssueWizardScreen({
    required this.requestor,
    required this.state,
    required this.onEvent,
  });

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
            if (state.plannedSteps.length > 1)
              IrmaProgressIndicator(
                step: state.currentStepIndex + 1,
                stepCount: state.plannedSteps.length,
              ),
            SizedBox(height: theme.defaultSpacing),
            IrmaQuote(
              richQuote: RichText(
                text: TextSpan(
                  children: [
                    if (state.plannedSteps.length > 1)
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
            DisclosureDisconStepper(
              currentCandidateIndex: state.currentDiscon?.key,
              candidates: state.candidates,
              selectedConIndices: state.selectedConIndices,
              onChoiceUpdated: (int conIndex) => onEvent(
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
        onPrimaryPressed: () => onEvent(DisclosurePermissionNextPressed()),
      ),
    );
  }
}

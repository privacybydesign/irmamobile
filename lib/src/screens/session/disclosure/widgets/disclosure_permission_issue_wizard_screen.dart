import 'package:flutter/widgets.dart';

import '../../../../models/session.dart';
import '../../../../theme/theme.dart';
import '../../../../widgets/irma_bottom_bar.dart';
import '../../../../widgets/requestor_header.dart';
import '../../../../widgets/session_progress_indicator.dart';
import '../../widgets/session_scaffold.dart';
import '../bloc/disclosure_permission_event.dart';
import '../bloc/disclosure_permission_state.dart';
import 'disclosure_discon_stepper.dart';

class DisclosurePermissionIssueWizardScreen extends StatelessWidget {
  final RequestorInfo requestor;
  final DisclosurePermissionIssueWizard state;
  final Function(DisclosurePermissionBlocEvent) onEvent;
  final Function({bool skipConfirmation}) onDismiss;

  const DisclosurePermissionIssueWizardScreen({
    required this.requestor,
    required this.state,
    required this.onEvent,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return SessionScaffold(
      appBarTitle: 'disclosure_permission.issue_wizard.title',
      onDismiss: onDismiss,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          theme.defaultSpacing,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RequestorHeader(
                requestorInfo: requestor,
                isVerified: !requestor.unverified,
              ),
              SessionProgressIndicator(
                step: state.currentStepIndex + 1,
                stepCount: state.plannedSteps.length,
                contentTranslationKey:
                    'disclosure_permission.issue_wizard.explanation_${state.isCompleted ? 'complete' : 'incomplete'}',
              ),
              DisclosureDisconStepper(
                currentCandidateKey: state.currentDiscon?.key,
                candidatesList: state.candidatesList,
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
      ),
      bottomNavigationBar: IrmaBottomBar(
        // If all steps in the wizard are completed, then we show the next button.
        // If the current step can be completed, then we show a obtain data button.
        // If the current step cannot be completed, then we show a close button.
        primaryButtonLabel: state.isCompleted
            ? 'disclosure_permission.next_step'
            : (state.currentCanBeCompleted ? 'disclosure_permission.obtain_data' : 'disclosure_permission.close'),
        onPrimaryPressed: state.currentCanBeCompleted
            ? () => onEvent(DisclosurePermissionNextPressed())
            : () => onDismiss(skipConfirmation: true),
      ),
    );
  }
}

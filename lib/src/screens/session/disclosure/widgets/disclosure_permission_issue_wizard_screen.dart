import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../models/session.dart';
import '../../../../theme/theme.dart';
import '../../../../widgets/irma_bottom_bar.dart';

import '../../../../widgets/issuer_verifier_header.dart';
import '../../widgets/session_scaffold.dart';
import '../bloc/disclosure_permission_event.dart';
import '../bloc/disclosure_permission_state.dart';
import 'disclosure_discon_stepper.dart';
import 'disclosure_permission_progress_indicator.dart';

class DisclosurePermissionIssueWizardScreen extends StatelessWidget {
  final RequestorInfo requestor;
  final DisclosurePermissionIssueWizard state;
  final Function(DisclosurePermissionBlocEvent) onEvent;
  final Function() onDismiss;

  const DisclosurePermissionIssueWizardScreen({
    required this.requestor,
    required this.state,
    required this.onEvent,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

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
              IssuerVerifierHeader(title: requestor.name.translate(lang)),
              DisclosurePermissionProgressIndicator(
                step: state.currentStepIndex + 1,
                stepCount: state.plannedSteps.length,
                contentTranslationKey:
                    'disclosure_permission.issue_wizard.explanation_${state.isCompleted ? 'complete' : 'incomplete'}',
              ),
              SizedBox(height: theme.defaultSpacing),
              DisclosureDisconStepper(
                currentCandidateKey: state.currentDiscon?.key,
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
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: state.isCompleted ? 'disclosure_permission.next_step' : 'disclosure_permission.obtain_data',
        onPrimaryPressed: () => onEvent(DisclosurePermissionNextPressed()),
      ),
    );
  }
}

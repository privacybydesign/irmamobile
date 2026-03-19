import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/session.dart";
import "../../../providers/issue_during_disclosure_provider.dart";
import "../../../providers/session_state_provider.dart";
import "../../../theme/theme.dart";
import "../../../util/navigation.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/requestor_header.dart";
import "../../../widgets/session_progress_indicator.dart";
import "disclosure_discon_stepper.dart";
import "session_scaffold.dart";

/// Shows the issuance-during-disclosure steps that the user needs to complete
/// before they can proceed with the disclosure.
///
/// Uses [IrmaStepper] to display steps as a timeline, matching the visual
/// style from the old disclosure permission issue wizard.
class IssueDuringDisclosureScreen extends ConsumerWidget {
  final int sessionId;
  final VoidCallback onDismiss;
  final VoidCallback? onCompleted;

  const IssueDuringDisclosureScreen({
    super.key,
    required this.sessionId,
    required this.onDismiss,
    this.onCompleted,
  });

  void _onObtainData(BuildContext context, CredentialDescriptor credential) {
    context.pushSchemalessDataDetailsScreen(
      AddDataDetailsRouteParams(credential: credential),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final wizardState = ref.watch(issueDuringDisclosureProvider(sessionId));
    final notifier = ref.read(
      issueDuringDisclosureProvider(sessionId).notifier,
    );

    final session = ref.watch(sessionStateProvider(sessionId)).value;
    final requestor = session?.requestor;

    final steps = wizardState.steps;
    final currentStepIndex = wizardState.currentStepIndex;
    final isCompleted = wizardState.isCompleted;

    return SessionScaffold(
      appBarTitle: "disclosure_permission.issue_wizard.title",
      onDismiss: onDismiss,
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: isCompleted
            ? "disclosure_permission.next_step"
            : "disclosure_permission.obtain_data",
        onPrimaryPressed: isCompleted
            ? (onCompleted ?? onDismiss)
            : () {
                _onObtainData(
                  context,
                  steps[currentStepIndex!].options[wizardState
                      .selectedOptionPerStep[currentStepIndex]],
                );
              },
        secondaryButtonLabel: "session.navigation_bar.cancel",
        onSecondaryPressed: onDismiss,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (requestor != null)
                RequestorHeader(
                  requestorInfo: RequestorInfo(
                    name: requestor.name,
                    logoPath: requestor.imagePath,
                  ),
                  isVerified: requestor.verified,
                ),
              SessionProgressIndicator(
                step: 1,
                stepCount: 2,
                contentTranslationKey: wizardState.explanationKey,
              ),
              DisclosureDisconStepper.fromState(
                wizardState: wizardState,
                notifier: notifier,
              ),
            ],
          ),
        ),
      ),
    );
  }

}

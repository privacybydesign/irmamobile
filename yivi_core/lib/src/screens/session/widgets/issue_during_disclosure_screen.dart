import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../models/session.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../providers/issue_during_disclosure_provider.dart";
import "../../../providers/session_state_provider.dart";
import "../../../theme/theme.dart";
import "../../../widgets/credential_card/yivi_credential_card.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_card.dart";
import "../../../widgets/irma_stepper.dart";
import "../../../widgets/radio_indicator.dart";
import "../../../widgets/requestor_header.dart";
import "../../../widgets/session_progress_indicator.dart";
import "../../../widgets/translated_text.dart";
import "session_scaffold.dart";

/// Shows the issuance-during-disclosure steps that the user needs to complete
/// before they can proceed with the disclosure.
///
/// Uses [IrmaStepper] to display steps as a timeline, matching the visual
/// style from the old disclosure permission issue wizard.
class IssueDuringDisclosureScreen extends ConsumerWidget {
  final int sessionId;
  final VoidCallback onDismiss;

  const IssueDuringDisclosureScreen({
    super.key,
    required this.sessionId,
    required this.onDismiss,
  });

  Future<void> _onObtainData(
    BuildContext context,
    WidgetRef ref,
    CredentialDescriptor credential,
  ) async {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final url = credential.issueURL?.translate(lang);
    if (url != null && url.isNotEmpty) {
      ref
          .read(irmaRepositoryProvider)
          .openIssueURL(
            context,
            credential.credentialId,
            credential.issueURL,
            ref,
          );
    }
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
    final isSingleStep = wizardState.isSingleStep;

    return SessionScaffold(
      appBarTitle: "disclosure_permission.issue_wizard.title",
      onDismiss: onDismiss,
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: isCompleted
            ? "disclosure_permission.next_step"
            : "disclosure_permission.obtain_data",
        onPrimaryPressed: isCompleted
            ? onDismiss
            : () {
                _onObtainData(
                  context,
                  ref,
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
              IrmaStepper(
                currentIndex: currentStepIndex,
                children: [
                  for (final (index, step) in steps.indexed)
                    _buildStepContent(
                      theme,
                      notifier,
                      wizardState,
                      step,
                      index,
                      currentStepIndex,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(
    IrmaThemeData theme,
    IssueDuringDisclosureNotifier notifier,
    IssueDuringDisclosureState wizardState,
    IssuanceStep step,
    int index,
    int? currentStepIndex,
  ) {
    final isCurrent = index == currentStepIndex;

    // Step with multiple options: show choice with radio buttons
    if (step.options.length > 1 && isCurrent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(theme.smallSpacing),
            child: TranslatedText(
              "disclosure_permission.choose",
              style: theme.themeData.textTheme.headlineMedium,
            ),
          ),
          for (var i = 0; i < step.options.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: theme.smallSpacing),
              child: GestureDetector(
                onTap: () => notifier.selectOption(index, i),
                child: YiviCredentialCard.fromDescriptor(
                  descriptor: step.options[i],
                  compact: true,
                  style: IrmaCardStyle.highlighted,
                  headerTrailing: RadioIndicator(
                    isSelected: i == wizardState.selectedOptionPerStep[index],
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Single option (or non-current multi-option): show selected credential card
    return Padding(
      padding: EdgeInsets.only(bottom: theme.smallSpacing),
      child: YiviCredentialCard.fromDescriptor(
        descriptor: step.options[wizardState.selectedOptionPerStep[index]],
        compact: true,
        style: isCurrent ? IrmaCardStyle.highlighted : IrmaCardStyle.normal,
      ),
    );
  }
}

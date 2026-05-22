import "package:flutter/material.dart";

import "../../../models/schemaless/session_state.dart";
import "../../../providers/issue_during_disclosure_provider.dart";
import "../../../theme/theme.dart";
import "../../../widgets/credential_card/yivi_credential_card.dart";
import "../../../widgets/irma_card.dart";
import "../../../widgets/irma_stepper.dart";
import "../../../widgets/translated_text.dart";
import "disclosure_permission_choice.dart";

/// A stepper widget that displays the issuance-during-disclosure steps.
///
/// Each step shows either a single credential card or a choice between
/// multiple credentials with radio buttons via [DisclosurePermissionChoice].
/// For multi-credential bundles, individual cards reflect per-credential
/// progress (done / next-to-issue / waiting) using [issuedCredentialIds].
class DisclosureDisconStepper extends StatelessWidget {
  final List<IssuanceStep> steps;
  final int? currentStepIndex;
  final List<int> selectedOptionPerStep;
  final Set<String> issuedCredentialIds;
  final ValueChanged<({int stepIndex, int optionIndex})>? onChoiceUpdated;

  const DisclosureDisconStepper({
    super.key,
    required this.steps,
    required this.currentStepIndex,
    required this.selectedOptionPerStep,
    required this.issuedCredentialIds,
    this.onChoiceUpdated,
  });

  factory DisclosureDisconStepper.fromState({
    Key? key,
    required IssueDuringDisclosureState wizardState,
    required IssueDuringDisclosureNotifier notifier,
  }) {
    return DisclosureDisconStepper(
      key: key,
      steps: wizardState.steps,
      currentStepIndex: wizardState.currentStepIndex,
      selectedOptionPerStep: wizardState.selectedOptionPerStep,
      issuedCredentialIds: wizardState.issuedCredentialIds,
      onChoiceUpdated: (choice) =>
          notifier.selectOption(choice.stepIndex, choice.optionIndex),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return IrmaStepper(
      currentIndex: currentStepIndex,
      children: [
        for (final (index, step) in steps.indexed)
          _buildStepContent(theme, step, index),
      ],
    );
  }

  Widget _buildStepContent(IrmaThemeData theme, IssuanceStep step, int index) {
    final isCurrent = index == currentStepIndex;

    // Step with multiple options: show choice with radio buttons.
    // Make-choice screen does not get per-card progress treatment — selection
    // is its concern, execution status is the stepper's.
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
          DisclosurePermissionChoice.fromIssuanceBundles(
            options: step.options,
            selectedIndex: selectedOptionPerStep[index],
            onChoiceUpdated: onChoiceUpdated != null
                ? (optionIndex) => onChoiceUpdated!((
                    stepIndex: index,
                    optionIndex: optionIndex,
                  ))
                : null,
          ),
        ],
      );
    }

    // Single option (or non-current multi-option): render the selected bundle.
    final bundle = step.options[selectedOptionPerStep[index]];

    // N=1 bundles render exactly like the pre-bundle code: a single card
    // styled as highlighted iff this step is current.
    if (bundle.credentials.length == 1) {
      return Padding(
        padding: EdgeInsets.only(bottom: theme.smallSpacing),
        child: YiviCredentialCard.fromDescriptor(
          descriptor: bundle.credentials.first,
          compact: true,
          style: isCurrent ? IrmaCardStyle.highlighted : IrmaCardStyle.normal,
        ),
      );
    }

    // N>1 bundle: per-card progress styling.
    // - next-to-issue (first non-done, only when this step is current):
    //   highlighted
    // - all others (done or waiting): normal
    //
    // The highlighted card moves down the column as credentials are issued,
    // which is the progress signal. The IrmaStepper's step indicator
    // conveys step-level completion separately.
    final firstNonDoneIndex = bundle.credentials.indexWhere(
      (c) => !issuedCredentialIds.contains(c.credentialId),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: theme.smallSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < bundle.credentials.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i < bundle.credentials.length - 1
                    ? theme.smallSpacing
                    : 0,
              ),
              child: YiviCredentialCard.fromDescriptor(
                descriptor: bundle.credentials[i],
                compact: true,
                style: isCurrent && i == firstNonDoneIndex
                    ? IrmaCardStyle.highlighted
                    : IrmaCardStyle.normal,
              ),
            ),
        ],
      ),
    );
  }
}

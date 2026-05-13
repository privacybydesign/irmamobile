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
class DisclosureDisconStepper extends StatelessWidget {
  final List<IssuanceStep> steps;
  final int? currentStepIndex;
  final List<int> selectedOptionPerStep;
  final ValueChanged<({int stepIndex, int optionIndex})>? onChoiceUpdated;

  const DisclosureDisconStepper({
    super.key,
    required this.steps,
    required this.currentStepIndex,
    required this.selectedOptionPerStep,
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
          DisclosurePermissionChoice.fromDescriptors(
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

    // Single option (or non-current multi-option): show selected credential card
    return Padding(
      padding: EdgeInsets.only(bottom: theme.smallSpacing),
      child: YiviCredentialCard.fromDescriptor(
        descriptor: step.options[selectedOptionPerStep[index]],
        compact: true,
        style: isCurrent ? IrmaCardStyle.highlighted : IrmaCardStyle.normal,
      ),
    );
  }
}

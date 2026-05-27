import "package:flutter/material.dart";

import "../../../models/schemaless/credential_store.dart";
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
/// Each [IssuanceStep] is rendered as one or more *virtual* stepper items so
/// the user sees one step per credential they have to obtain:
///
/// - **Single-option, single-cred bundle**: one stepper item (the card).
/// - **Single-option, multi-cred bundle**: one stepper item *per credential*
///   in the bundle — so the IrmaStepper's per-item progress indicator
///   (filled / outlined / success) reflects per-credential progress.
/// - **Multi-option step (the choice case)**: one stepper item, with the
///   existing [DisclosurePermissionChoice] inside.
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
    final virtualSteps = _buildVirtualSteps();
    final currentVirtual = _findCurrentVirtualStepIndex(virtualSteps);

    return IrmaStepper(
      currentIndex: currentVirtual,
      children: [
        for (var i = 0; i < virtualSteps.length; i++)
          _renderVirtualStep(theme, virtualSteps[i], i == currentVirtual),
      ],
    );
  }

  List<_VirtualStep> _buildVirtualSteps() {
    final result = <_VirtualStep>[];
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      final isCurrent = i == currentStepIndex;
      if (step.options.length > 1 && isCurrent) {
        // Multi-option step that is current: render the choice.
        result.add(_ChoiceVirtualStep(i, step));
      } else {
        // Single-option step, or a multi-option step that's already
        // satisfied / still in the future. For satisfied multi-option steps
        // prefer the bundle whose credentials are all issued, so the user
        // sees what they actually obtained instead of the default selection.
        final bundle = _bundleForNonChoiceStep(step, i);
        for (final descriptor in bundle.credentials) {
          result.add(_CredentialVirtualStep(i, descriptor));
        }
      }
    }
    return result;
  }

  IssuanceBundle _bundleForNonChoiceStep(IssuanceStep step, int stepIndex) {
    bool isSatisfied(IssuanceBundle bundle) =>
        bundle.credentials.isNotEmpty &&
        bundle.credentials.every(
          (d) => issuedCredentialIds.contains(d.credentialId),
        );

    // Clamp the selected index defensively so a stale selection cannot blow
    // up. _buildFromSession already clamps, but the stepper may render with an
    // index from a previous frame during transitions.
    final rawSelected = stepIndex < selectedOptionPerStep.length
        ? selectedOptionPerStep[stepIndex]
        : 0;
    final selectedIndex =
        (rawSelected >= 0 && rawSelected < step.options.length)
        ? rawSelected
        : 0;

    // Prefer the user-selected bundle. Only fall back to *some* satisfied
    // bundle when the user has not made an explicit choice (or it isn't yet
    // satisfied) — this still shows what the user has obtained when the step
    // is in the past, without overriding the user's intent.
    if (step.options.length > 1) {
      final selectedBundle = step.options[selectedIndex];
      if (isSatisfied(selectedBundle)) return selectedBundle;
      for (final bundle in step.options) {
        if (isSatisfied(bundle)) return bundle;
      }
    }
    return step.options[selectedIndex];
  }

  /// Locate the first virtual step that belongs to the current
  /// [IssuanceStep] and isn't already done.
  int? _findCurrentVirtualStepIndex(List<_VirtualStep> virtualSteps) {
    if (currentStepIndex == null) return null;
    for (var i = 0; i < virtualSteps.length; i++) {
      final vs = virtualSteps[i];
      if (vs.issuanceStepIndex != currentStepIndex) continue;
      switch (vs) {
        case _ChoiceVirtualStep():
          return i;
        case _CredentialVirtualStep(:final descriptor):
          if (!issuedCredentialIds.contains(descriptor.credentialId)) {
            return i;
          }
      }
    }
    return null;
  }

  Widget _renderVirtualStep(
    IrmaThemeData theme,
    _VirtualStep vs,
    bool isCurrent,
  ) {
    switch (vs) {
      case _ChoiceVirtualStep(:final step, :final issuanceStepIndex):
        return _renderChoice(theme, step, issuanceStepIndex);
      case _CredentialVirtualStep(:final descriptor):
        return Padding(
          padding: EdgeInsets.only(bottom: theme.smallSpacing),
          child: YiviCredentialCard.fromDescriptor(
            descriptor: descriptor,
            compact: true,
            style: isCurrent ? IrmaCardStyle.highlighted : IrmaCardStyle.normal,
          ),
        );
    }
  }

  int _clampedSelectedIndex(int stepIndex, IssuanceStep step) {
    if (step.options.isEmpty) return 0;
    final raw = stepIndex < selectedOptionPerStep.length
        ? selectedOptionPerStep[stepIndex]
        : 0;
    return (raw >= 0 && raw < step.options.length) ? raw : 0;
  }

  Widget _renderChoice(
    IrmaThemeData theme,
    IssuanceStep step,
    int issuanceStepIndex,
  ) {
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
          selectedIndex: _clampedSelectedIndex(issuanceStepIndex, step),
          onChoiceUpdated: onChoiceUpdated != null
              ? (optionIndex) => onChoiceUpdated!((
                  stepIndex: issuanceStepIndex,
                  optionIndex: optionIndex,
                ))
              : null,
        ),
      ],
    );
  }
}

/// Tagged union of stepper items the [DisclosureDisconStepper] renders.
sealed class _VirtualStep {
  final int issuanceStepIndex;
  const _VirtualStep(this.issuanceStepIndex);
}

class _ChoiceVirtualStep extends _VirtualStep {
  final IssuanceStep step;
  const _ChoiceVirtualStep(super.issuanceStepIndex, this.step);
}

class _CredentialVirtualStep extends _VirtualStep {
  final CredentialDescriptor descriptor;
  const _CredentialVirtualStep(super.issuanceStepIndex, this.descriptor);
}

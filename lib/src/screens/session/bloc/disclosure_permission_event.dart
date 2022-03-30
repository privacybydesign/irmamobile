abstract class DisclosurePermissionBlocEvent {}

/// Event to indicate that the user changed a choice for the upcoming issue wizard.
class DisclosurePermissionIssueWizardChoiceUpdated implements DisclosurePermissionBlocEvent {
  final int stepIndex;
  final int choiceIndex;

  DisclosurePermissionIssueWizardChoiceUpdated({required this.stepIndex, required this.choiceIndex});
}

/// Event to indicate that the user wants to continue to the next state.
class DisclosurePermissionNextPressed implements DisclosurePermissionBlocEvent {}

/// Event to indicate for which step all available choices should be displayed.
/// If stepIndex is null, then all steps should be collapsed.
class DisclosurePermissionStepSelected implements DisclosurePermissionBlocEvent {
  final int? stepIndex;

  DisclosurePermissionStepSelected({required this.stepIndex});
}

/// Event to indicate that the user changed a choice in one of the choice steps to select which data will be disclosed.
class DisclosurePermissionChoiceUpdated implements DisclosurePermissionBlocEvent {
  final int stepIndex;
  final int choiceIndex;

  DisclosurePermissionChoiceUpdated({required this.stepIndex, required this.choiceIndex});
}

/// Event to indicate that the user wants to change the current selection in the confirmation phase.
class DisclosurePermissionEditCurrentSelectionPressed implements DisclosurePermissionBlocEvent {}

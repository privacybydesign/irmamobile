abstract class DisclosurePermissionBlocEvent {}

/// Event to indicate that the user changed a choice for the upcoming issue wizard.
class IssueWizardChoiceBlocEvent implements DisclosurePermissionBlocEvent {
  final int stepIndex;
  final int choiceIndex;

  IssueWizardChoiceBlocEvent({required this.stepIndex, required this.choiceIndex});
}

/// Event to indicate that the user wants to continue to the next state.
class GoToNextStateBlocEvent implements DisclosurePermissionBlocEvent {}

/// Event to indicate for which step all available choices should be displayed.
/// If stepIndex is null, then all steps should be collapsed.
class SelectStepBlocEvent implements DisclosurePermissionBlocEvent {
  final int? stepIndex;

  SelectStepBlocEvent({required this.stepIndex});
}

/// Event to indicate that the user changed a choice in one of the choice steps to select which data will be disclosed.
class UpdateChoiceBlocEvent implements DisclosurePermissionBlocEvent {
  final int stepIndex;
  final int choiceIndex;

  UpdateChoiceBlocEvent({required this.stepIndex, required this.choiceIndex});
}

/// Event to indicate that the user wants to change the choices in the confirmation phase.
class ChangeChoicesBlocEvent implements DisclosurePermissionBlocEvent {}

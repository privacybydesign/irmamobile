abstract class DisclosurePermissionBlocEvent {}

/// Event to indicate that the user changed a choice for the upcoming issue wizard.
class IssueWizardChoiceEvent implements DisclosurePermissionBlocEvent {
  final int stepIndex;
  final int choiceIndex;

  IssueWizardChoiceEvent({required this.stepIndex, required this.choiceIndex});
}

/// Event to indicate that the user wants to continue to the next state.
class GoToNextStateEvent implements DisclosurePermissionBlocEvent {}

/// Event to indicate for which step all available choices should be displayed.
/// If stepIndex is null, then all steps should be collapsed.
class DisclosureSelectStepEvent implements DisclosurePermissionBlocEvent {
  final int? stepIndex;

  DisclosureSelectStepEvent({required this.stepIndex});
}

/// Event to indicate that the user changed a choice in one of the choice steps to select which data will be disclosed.
class DisclosureUpdateChoiceEvent implements DisclosurePermissionBlocEvent {
  final int stepIndex;
  final int choiceIndex;

  DisclosureUpdateChoiceEvent({required this.stepIndex, required this.choiceIndex});
}

/// Event to indicate that the user wants to change the choices in the confirmation phase.
class DisclosureChangeChoicesEvent implements DisclosurePermissionBlocEvent {}

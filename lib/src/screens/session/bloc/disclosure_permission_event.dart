abstract class DisclosurePermissionBlocEvent {}

/// Event to indicate that the user changed a choice for the upcoming issue wizard.
class IssueWizardChoiceEvent implements DisclosurePermissionBlocEvent {
  final int stepIndex;
  final int choiceIndex;

  IssueWizardChoiceEvent({required this.stepIndex, required this.choiceIndex});
}

/// Event to indicate that the user wants to continue to the next state.
class GoToNextStateEvent implements DisclosurePermissionBlocEvent {}

/// Event to indicate that all available choices of the given step should be displayed.
class DisclosureViewAllChoicesEvent implements DisclosurePermissionBlocEvent {
  final int stepIndex;

  DisclosureViewAllChoicesEvent({required this.stepIndex});
}

/// Event to indicate that the user changed a choice in one of the choice steps to select which data will be disclosed.
class DisclosureUpdateChoiceEvent implements DisclosurePermissionBlocEvent {
  final int stepIndex;
  final int choiceIndex;

  DisclosureUpdateChoiceEvent({required this.stepIndex, required this.choiceIndex});
}

/// Event to indicate that the user confirms the current choices in a particular step.
class DisclosureConfirmChoiceEvent implements DisclosurePermissionBlocEvent {
  final int stepIndex;

  DisclosureConfirmChoiceEvent({required this.stepIndex});
}

/// Event to indicate that the user wants to change the choices in the confirmation phase.
class DisclosureChangeChoicesEvent implements DisclosurePermissionBlocEvent {}

abstract class DisclosurePermissionBlocEvent {}

/// Event to indicate that the user wants to continue to the next state.
class DisclosurePermissionNextPressed implements DisclosurePermissionBlocEvent {}

/// Event to indicate that the user wants to go back to the previous state.
class DisclosurePermissionPreviousPressed implements DisclosurePermissionBlocEvent {}

/// Event to indicate for which discon in the condiscon all available choices should be displayed.
class DisclosurePermissionChangeChoicePressed implements DisclosurePermissionBlocEvent {
  final int disconIndex;

  DisclosurePermissionChangeChoicePressed({required this.disconIndex});
}

/// Event to indicate that the user has pressed the button to add more optional data.
class DisclosurePermissionAddOptionalDataPressed implements DisclosurePermissionBlocEvent {}

/// Event to indicate that the user wants to remove a certain discon from the current choices.
class DisclosurePermissionRemoveOptionalDataPressed implements DisclosurePermissionBlocEvent {
  final int disconIndex;

  DisclosurePermissionRemoveOptionalDataPressed({required this.disconIndex});
}

/// Event to indicate that the user changed a choice in the discon that is currently displayed.
class DisclosurePermissionChoiceUpdated implements DisclosurePermissionBlocEvent {
  final int conIndex;

  DisclosurePermissionChoiceUpdated({required this.conIndex});
}

/// Event to indicate that the user dismisses a dialog.
class DisclosurePermissionDialogDismissed implements DisclosurePermissionBlocEvent {}

/// Event to indicate that the user wants to dismiss the disclosure permission request.
class DisclosurePermissionDismissed implements DisclosurePermissionBlocEvent {}

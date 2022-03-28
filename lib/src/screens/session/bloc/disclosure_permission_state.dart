import 'package:collection/collection.dart';

import '../../../models/attributes.dart';
import '../models/abstract_disclosure_credential.dart';
import '../models/disclosure_credential.dart';
import '../models/disclosure_credential_template.dart';

abstract class DisclosurePermissionBlocState {}

/// Initial state to give us time to process the initial request from the IrmaBridge.
class WaitingForSessionState implements DisclosurePermissionBlocState {}

class DisclosurePermissionIssueWizardChoiceState implements DisclosurePermissionBlocState {
  /// ConDisCon representing all choices between templates to fill the issueWizard.
  final ConDisCon<DisclosureCredentialTemplate> issueWizardChoices;

  /// List with indices of the currently selected disjunctions in issueWizardChoices.
  final UnmodifiableListView<int> issueWizardChoiceIndices;

  DisclosurePermissionIssueWizardChoiceState({required this.issueWizardChoices, List<int>? issueWizardChoiceIndices})
      : issueWizardChoiceIndices = UnmodifiableListView(issueWizardChoiceIndices ?? issueWizardChoices.map((_) => 0));

  /// Templates of all DisclosureCredentials that needs to be obtained first.
  Iterable<DisclosureCredentialTemplate> get issueWizard =>
      issueWizardChoices.asMap().entries.expand((entry) => entry.value[issueWizardChoiceIndices[entry.key]]);
}

// TODO: Do we want to display optional credentials in the wizard?
class DisclosurePermissionIssueWizardState implements DisclosurePermissionBlocState {
  /// Templates of all DisclosureCredentials that needs to be obtained first.
  final List<DisclosureCredentialTemplate> issueWizard;

  bool get completed => issueWizard.every((template) => template.obtained);

  DisclosurePermissionIssueWizardState({required this.issueWizard});
}

class DisclosurePermissionChoiceState implements DisclosurePermissionBlocState {
  /// Index of the currently expanded step, to keep track which choice the user is currently making.
  /// If all choices are collapsed, the value is null.
  final int? selectedStepIndex;

  /// ConDisCon representing choices that need to be made when there are multiple options to disclose.
  /// TODO: Can't we immediately filter out the templates?
  final ConDisCon<AbstractDisclosureCredential> choices;

  /// List with indices of the currently selected disjunctions in choices.
  final UnmodifiableListView<int> choiceIndices;

  DisclosurePermissionChoiceState({required this.choices, this.selectedStepIndex, List<int>? choiceIndices})
      : assert(choiceIndices == null || choices.length == choiceIndices.length),
        choiceIndices = UnmodifiableListView(choiceIndices ?? choices.map((_) => 0));

  /// ConCon with all DisclosureCredentials currently selected to be disclosed.
  ConCon<DisclosureCredential> get currentSelection => ConCon(
      choices.asMap().entries.map((entry) => Con(entry.value[choiceIndices[entry.key]].cast<DisclosureCredential>())));
}

class DisclosurePermissionConfirmState implements DisclosurePermissionBlocState {
  // TODO: signatures.

  /// List with all DisclosureCredentials currently selected to be disclosed.
  final UnmodifiableListView<DisclosureCredential> currentSelection;

  DisclosurePermissionConfirmState({required List<DisclosureCredential> currentSelection})
      : currentSelection = UnmodifiableListView(currentSelection);
}

/// State to indicate that the requestDisclosurePermission phase has been completed.
/// This does not necessarily have to mean the full session is completed.
class DisclosurePermissionCompletedState implements DisclosurePermissionBlocState {}

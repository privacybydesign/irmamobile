import 'package:collection/collection.dart';

import '../../../../models/attributes.dart';
import '../../models/choosable_disclosure_credential.dart';
import '../../models/disclosure_credential.dart';
import '../../models/template_disclosure_credential.dart';

abstract class DisclosurePermissionBlocState {}

/// Initial state to give us time to process the initial request from the IrmaBridge.
class DisclosurePermissionInitial implements DisclosurePermissionBlocState {}

class DisclosurePermissionIssueWizardChoices implements DisclosurePermissionBlocState {
  /// ConDisCon representing all choices between templates to fill the issueWizard.
  final ConDisCon<TemplateDisclosureCredential> issueWizardChoices;

  /// List with indices of the currently selected disjunctions in issueWizardChoices.
  final UnmodifiableListView<int> issueWizardChoiceIndices;

  DisclosurePermissionIssueWizardChoices({required this.issueWizardChoices, List<int>? issueWizardChoiceIndices})
      : issueWizardChoiceIndices = UnmodifiableListView(issueWizardChoiceIndices ?? issueWizardChoices.map((_) => 0));

  /// Templates of all DisclosureCredentials that needs to be obtained first.
  Iterable<TemplateDisclosureCredential> get issueWizard =>
      issueWizardChoices.asMap().entries.expand((entry) => entry.value[issueWizardChoiceIndices[entry.key]]);
}

class DisclosurePermissionIssueWizard implements DisclosurePermissionBlocState {
  /// Templates of all DisclosureCredentials that needs to be obtained first.
  final UnmodifiableListView<TemplateDisclosureCredential> issueWizard;

  /// List with the latest obtained credential for each issue wizard item (matching and non-matching).
  final UnmodifiableListView<ChoosableDisclosureCredential?> obtainedCredentials;

  /// Returns for each issue wizard item whether a matching credential has been successfully obtained.
  List<bool> get obtainedCredentialsMatch => obtainedCredentials
      .mapIndexed((i, cred) => cred != null && issueWizard[i].matchesDisclosureCredential(cred))
      .toList();

  /// Returns whether all issue wizard items have a matching credential.
  bool get allObtainedCredentialsMatch => obtainedCredentialsMatch.every((match) => match);

  DisclosurePermissionIssueWizard({
    required List<TemplateDisclosureCredential> issueWizard,
    List<ChoosableDisclosureCredential?>? obtainedCredentials,
  })  : assert(obtainedCredentials == null || obtainedCredentials.length == issueWizard.length),
        issueWizard = UnmodifiableListView(issueWizard),
        obtainedCredentials = UnmodifiableListView(obtainedCredentials ?? List.filled(issueWizard.length, null));
}

class DisclosurePermissionChoices implements DisclosurePermissionBlocState {
  /// Index of the currently expanded step, to keep track which choice the user is currently making.
  /// If all choices are collapsed, the value is null.
  final int? selectedStepIndex;

  /// ConDisCon representing choices that need to be made when there are multiple options to disclose.
  /// This includes all TemplateDisclosureCredentials, such that they can be presented as placeholders.
  /// These templates are not choosable.
  final ConDisCon<DisclosureCredential> choices;

  /// List with indices of the currently selected disjunctions in choices.
  final UnmodifiableListView<int> choiceIndices;

  DisclosurePermissionChoices({required this.choices, this.selectedStepIndex, List<int>? choiceIndices})
      : assert(choiceIndices == null || choices.length == choiceIndices.length),
        choiceIndices = UnmodifiableListView(choiceIndices ?? choices.map((_) => 0));

  /// List with all ChoosableDisclosureCredentials currently selected to be disclosed.
  List<ChoosableDisclosureCredential> get currentSelection => choices
      .asMap()
      .entries
      .map((entry) => Con(entry.value[choiceIndices[entry.key]].cast<ChoosableDisclosureCredential>()))
      .flattened
      .toList();
}

class DisclosurePermissionConfirmChoices implements DisclosurePermissionBlocState {
  /// List with all ChoosableDisclosureCredentials currently selected to be disclosed.
  final UnmodifiableListView<ChoosableDisclosureCredential> currentSelection;

  /// Message to be signed, in case of a signature session.
  final String? signedMessage;

  /// Returns whether the session is a signature session.
  bool get isSignatureSession => signedMessage != null && signedMessage != '';

  DisclosurePermissionConfirmChoices({
    required List<ChoosableDisclosureCredential> currentSelection,
    this.signedMessage,
  }) : currentSelection = UnmodifiableListView(currentSelection);
}

/// State to indicate that the requestDisclosurePermission phase has been finished.
/// This does not necessarily have to mean the total session is completed.
class DisclosurePermissionFinished implements DisclosurePermissionBlocState {}

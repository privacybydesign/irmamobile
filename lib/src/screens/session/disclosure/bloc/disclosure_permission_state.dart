import 'package:collection/collection.dart';
import 'package:irmamobile/src/screens/session/disclosure/models/disclosure_con_dis_con.dart';

import '../models/choosable_disclosure_credential.dart';
import '../models/disclosure_dis_con.dart';
import '../models/template_disclosure_credential.dart';

abstract class DisclosurePermissionBlocState {}

/// Initial state to give us time to process the initial request from the IrmaBridge.
class DisclosurePermissionInitial implements DisclosurePermissionBlocState {}

/// Enum with all possible DisclosurePermissionSteps.
enum DisclosurePermissionStepName {
  issueWizard,
  previouslyAddedCredentialsOverview,
  choicesOverview,
}

/// Abstract class containing all behaviour every named step in the DisclosurePermission flow has.
abstract class DisclosurePermissionStep implements DisclosurePermissionBlocState {
  /// List with all the planned steps.
  final UnmodifiableListView<DisclosurePermissionStepName> plannedSteps;

  /// DisclosureConDisCon with all disclosure candidates (required and optional).
  final DisclosureConDisCon condiscon;

  DisclosurePermissionStep({required List<DisclosurePermissionStepName> plannedSteps, required this.condiscon})
      : plannedSteps = UnmodifiableListView(plannedSteps);

  /// Index of the current step in the list of planned steps.
  DisclosurePermissionStepName get currentStepName;

  /// Index of the current step in the list of planned steps.
  int get currentStepIndex => plannedSteps.indexWhere((stepName) => stepName == currentStepName);
}

class DisclosurePermissionIssueWizard extends DisclosurePermissionStep {
  /// Returns the index of the discon that should currently be handled.
  /// Returns -1 if the issue wizard is completed.
  int get currentDisconIndex =>
      condiscon.required.toList().indexWhere((choice) => choice.selectedCon.needsToBeObtained);

  /// Returns the discon that should currently be handled.
  DisclosureDisCon? get currentDiscon =>
      condiscon.required.firstWhereOrNull((choice) => choice.selectedCon.needsToBeObtained);

  /// Returns whether the issue wizard is completed.
  bool get isCompleted => condiscon.required.every((choice) => !choice.selectedCon.needsToBeObtained);

  DisclosurePermissionIssueWizard({
    required List<DisclosurePermissionStepName> plannedSteps,
    required DisclosureConDisCon condiscon,
  }) : super(plannedSteps: plannedSteps, condiscon: condiscon);

  @override
  DisclosurePermissionStepName get currentStepName => DisclosurePermissionStepName.issueWizard;
}

class DisclosurePermissionSubIssueWizard implements DisclosurePermissionBlocState {
  /// Link to the state that initiated this SubIssueWizard.
  final DisclosurePermissionBlocState parentState;

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

  bool get hasObtainedCredentials => obtainedCredentials.any((cred) => cred != null);

  /// Returns the current issue wizard item.
  TemplateDisclosureCredential? get currentIssueWizardItem =>
      issueWizard.firstWhereIndexedOrNull((i, item) => !obtainedCredentialsMatch[i]);

  DisclosurePermissionSubIssueWizard({
    required this.parentState,
    required List<TemplateDisclosureCredential> issueWizard,
    List<ChoosableDisclosureCredential?>? obtainedCredentials,
  })  : assert(obtainedCredentials == null || obtainedCredentials.length == issueWizard.length),
        issueWizard = UnmodifiableListView(issueWizard),
        obtainedCredentials = UnmodifiableListView(obtainedCredentials ?? List.filled(issueWizard.length, null));
}

class DisclosurePermissionPreviouslyAddedCredentialsOverview extends DisclosurePermissionStep {
  DisclosurePermissionPreviouslyAddedCredentialsOverview({
    required List<DisclosurePermissionStepName> plannedSteps,
    required DisclosureConDisCon condiscon,
  }) : super(plannedSteps: plannedSteps, condiscon: condiscon);

  @override
  DisclosurePermissionStepName get currentStepName => DisclosurePermissionStepName.previouslyAddedCredentialsOverview;
}

class DisclosurePermissionChoicesOverview extends DisclosurePermissionStep {
  /// Message to be signed, in case of a signature session.
  final String? signedMessage;

  /// Returns whether the session is a signature session.
  bool get isSignatureSession => signedMessage != null;

  /// Returns whether the popup should be shown that asks for confirmation to share data.
  final bool showConfirmationPopup;

  DisclosurePermissionChoicesOverview({
    required List<DisclosurePermissionStepName> plannedSteps,
    required DisclosureConDisCon condiscon,
    this.signedMessage,
    this.showConfirmationPopup = false,
  }) : super(plannedSteps: plannedSteps, condiscon: condiscon);

  @override
  DisclosurePermissionStepName get currentStepName => DisclosurePermissionStepName.choicesOverview;
}

class DisclosurePermissionChangeChoice implements DisclosurePermissionBlocState {
  /// Link to the state that initiated this state.
  final DisclosurePermissionStep parentState;

  /// DisCon that should be changed.
  final DisclosureDisCon discon;

  DisclosurePermissionChangeChoice({
    required this.parentState,
    required this.discon,
  });
}

/// State to indicate that the requestDisclosurePermission phase has been finished.
/// This does not necessarily have to mean the total session is completed.
class DisclosurePermissionFinished implements DisclosurePermissionBlocState {}

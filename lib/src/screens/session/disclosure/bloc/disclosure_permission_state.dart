import 'package:collection/collection.dart';

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

  /// ConDisCon with all disclosure candidates being relevant in this step (required and optional).
  /// They are stored in a map with the disconIndex being used as map key.
  final Map<int, DisclosureDisCon> candidates;

  DisclosurePermissionStep({required List<DisclosurePermissionStepName> plannedSteps, required this.candidates})
      : plannedSteps = UnmodifiableListView(plannedSteps);

  /// Index of the current step in the list of planned steps.
  DisclosurePermissionStepName get currentStepName;

  /// Index of the current step in the list of planned steps.
  int get currentStepIndex => plannedSteps.indexWhere((stepName) => stepName == currentStepName);

  /// List with all required DisCons. In required DisCons a choice between one of the options must be made.
  Map<int, DisclosureDisCon> get requiredCandidates =>
      Map.fromEntries(candidates.entries.where((entry) => !entry.value.isOptional));

  /// List with all optional DisCons. In optional DisCons there is an option to select none of the choices.
  Map<int, DisclosureDisCon> get optionalCandidates =>
      Map.fromEntries(candidates.entries.where((entry) => entry.value.isOptional));
}

// TODO: does this need the full candidates condiscon?
class DisclosurePermissionIssueWizard extends DisclosurePermissionStep {
  /// Returns the discon that should currently be handled.
  DisclosureDisCon? get currentDiscon =>
      requiredCandidates.values.firstWhereOrNull((discon) => discon.choosableCons.isEmpty);

  /// Returns whether the issue wizard is completed.
  bool get isCompleted => requiredCandidates.values.every((discon) => discon.isSelectedChoosable);

  DisclosurePermissionIssueWizard({
    required List<DisclosurePermissionStepName> plannedSteps,
    required Map<int, DisclosureDisCon> candidates,
  }) : super(plannedSteps: plannedSteps, candidates: candidates);

  @override
  DisclosurePermissionStepName get currentStepName => DisclosurePermissionStepName.issueWizard;
}

class DisclosurePermissionPreviouslyAddedCredentialsOverview extends DisclosurePermissionStep {
  DisclosurePermissionPreviouslyAddedCredentialsOverview({
    required List<DisclosurePermissionStepName> plannedSteps,
    required Map<int, DisclosureDisCon> candidates,
  }) : super(plannedSteps: plannedSteps, candidates: candidates);

  @override
  DisclosurePermissionStepName get currentStepName => DisclosurePermissionStepName.previouslyAddedCredentialsOverview;
}

// TODO: does this need the full candidates condiscon?
class DisclosurePermissionChoicesOverview extends DisclosurePermissionStep {
  /// Message to be signed, in case of a signature session.
  final String? signedMessage;

  /// Returns whether the session is a signature session.
  bool get isSignatureSession => signedMessage != null;

  /// Returns whether the popup should be shown that asks for confirmation to share data.
  final bool showConfirmationPopup;

  DisclosurePermissionChoicesOverview({
    required List<DisclosurePermissionStepName> plannedSteps,
    required Map<int, DisclosureDisCon> candidates,
    this.signedMessage,
    this.showConfirmationPopup = false,
  }) : super(plannedSteps: plannedSteps, candidates: candidates);

  @override
  DisclosurePermissionStepName get currentStepName => DisclosurePermissionStepName.choicesOverview;
}

class DisclosurePermissionObtainCredentials implements DisclosurePermissionBlocState {
  /// Link to the state that initiated this SubIssueWizard.
  final DisclosurePermissionBlocState parentState;

  /// Templates of all DisclosureCredentials that needs to be obtained first.
  final UnmodifiableListView<TemplateDisclosureCredential> templates;

  /// List with the latest obtained credential for each issue wizard item (matching and non-matching).
  final UnmodifiableListView<ChoosableDisclosureCredential?> obtainedCredentials;

  /// Returns for each issue wizard item whether a matching credential has been successfully obtained.
  List<bool> get obtainedCredentialsMatch => obtainedCredentials
      .mapIndexed((i, cred) => cred != null && templates[i].matchesDisclosureCredential(cred))
      .toList();

  /// Returns whether all issue wizard items have a matching credential.
  bool get allObtainedCredentialsMatch => obtainedCredentialsMatch.every((match) => match);

  bool get hasObtainedCredentials => obtainedCredentials.any((cred) => cred != null);

  /// Returns the current issue wizard item.
  TemplateDisclosureCredential? get currentIssueWizardItem =>
      templates.firstWhereIndexedOrNull((i, item) => !obtainedCredentialsMatch[i]);

  DisclosurePermissionObtainCredentials({
    required this.parentState,
    required List<TemplateDisclosureCredential> templates,
    List<ChoosableDisclosureCredential?>? obtainedCredentials,
  })  : assert(obtainedCredentials == null || obtainedCredentials.length == templates.length),
        templates = UnmodifiableListView(templates),
        obtainedCredentials = UnmodifiableListView(obtainedCredentials ?? List.filled(templates.length, null));
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

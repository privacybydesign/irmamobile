import 'package:collection/collection.dart';
import 'package:irmamobile/src/models/attributes.dart';

import '../models/choosable_disclosure_credential.dart';
import '../models/disclosure_credential.dart';
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

/// Abstract class containing all behaviour every state that is a planned.
abstract class DisclosurePermissionStep implements DisclosurePermissionBlocState {
  /// List with all the planned steps.
  final UnmodifiableListView<DisclosurePermissionStepName> plannedSteps;

  DisclosurePermissionStep({required List<DisclosurePermissionStepName> plannedSteps})
      : plannedSteps = UnmodifiableListView(plannedSteps);

  /// Index of the current step in the list of planned steps.
  DisclosurePermissionStepName get currentStepName;

  /// Index of the current step in the list of planned steps.
  int get currentStepIndex => plannedSteps.indexWhere((stepName) => stepName == currentStepName);
}

/// Abstract class containing all behaviour for states that contain disclosure choices.
abstract class DisclosurePermissionChoices extends DisclosurePermissionStep {
  final UnmodifiableMapView<int, Con<ChoosableDisclosureCredential>> choices;

  /// Map that for each choice specifies whether it is optional or not.
  final UnmodifiableMapView<int, bool> isOptional;

  DisclosurePermissionChoices({
    required List<DisclosurePermissionStepName> plannedSteps,
    required Map<int, Con<ChoosableDisclosureCredential>> choices,
    required Map<int, bool> isOptional,
  })  : assert(isOptional.length == choices.length),
        choices = UnmodifiableMapView(choices),
        isOptional = UnmodifiableMapView(isOptional),
        super(plannedSteps: plannedSteps);

  /// List with all required choices. In required choices a choice between one of the options must be made.
  Map<int, Con<ChoosableDisclosureCredential>> get requiredChoices =>
      Map.fromEntries(choices.entries.where((entry) => !isOptional[entry.key]!));

  /// List with all optional choices. In optional choices there is an option to select none of the choices.
  Map<int, Con<ChoosableDisclosureCredential>> get optionalChoices =>
      Map.fromEntries(choices.entries.where((entry) => isOptional[entry.key]!));
}

class DisclosurePermissionIssueWizard extends DisclosurePermissionStep {
  /// ConDisCon with all disclosure candidates being relevant in this step (required and optional).
  /// They are stored in a map with the disconIndex being used as map key.
  final UnmodifiableMapView<int, DisCon<DisclosureCredential>> candidates;

  /// Stores for every discon which con is currently selected.
  final UnmodifiableMapView<int, int> selectedConIndices;

  DisclosurePermissionIssueWizard({
    required List<DisclosurePermissionStepName> plannedSteps,
    required Map<int, DisCon<DisclosureCredential>> candidates,
    required Map<int, int> selectedConIndices,
  })  : assert(candidates.keys.every((i) => selectedConIndices.containsKey(i))),
        candidates = UnmodifiableMapView(candidates),
        selectedConIndices = UnmodifiableMapView(selectedConIndices),
        super(plannedSteps: plannedSteps);

  /// Returns the discon that should currently be handled.
  MapEntry<int, DisCon<DisclosureCredential>>? get currentDiscon => requiredCandidates.entries
      .firstWhereOrNull((entry) => entry.value.every((con) => con.any((cred) => cred is TemplateDisclosureCredential)));

  /// Returns whether the issue wizard is completed.
  bool get isCompleted => currentDiscon == null;

  /// List with all required DisCons. In required DisCons a choice between one of the options must be made.
  Map<int, DisCon<DisclosureCredential>> get requiredCandidates =>
      Map.fromEntries(candidates.entries.where((entry) => !entry.value.any((discon) => discon.isEmpty)));

  /// List with all optional DisCons. In optional DisCons there is an option to select none of the choices.
  Map<int, DisCon<DisclosureCredential>> get optionalCandidates =>
      Map.fromEntries(candidates.entries.where((entry) => entry.value.any((discon) => discon.isEmpty)));

  @override
  DisclosurePermissionStepName get currentStepName => DisclosurePermissionStepName.issueWizard;

  /// Returns for the given disconIndex the selected con.
  Con<DisclosureCredential>? getSelectedCon(int disconIndex) =>
      candidates[disconIndex]?[selectedConIndices[disconIndex]!];
}

class DisclosurePermissionPreviouslyAddedCredentialsOverview extends DisclosurePermissionChoices {
  DisclosurePermissionPreviouslyAddedCredentialsOverview({
    required List<DisclosurePermissionStepName> plannedSteps,
    required Map<int, Con<ChoosableDisclosureCredential>> choices,
    required Map<int, bool> isOptional,
  }) : super(plannedSteps: plannedSteps, choices: choices, isOptional: isOptional);

  @override
  DisclosurePermissionStepName get currentStepName => DisclosurePermissionStepName.previouslyAddedCredentialsOverview;
}

class DisclosurePermissionChoicesOverview extends DisclosurePermissionChoices {
  /// Message to be signed, in case of a signature session.
  final String? signedMessage;

  /// Returns whether the session is a signature session.
  bool get isSignatureSession => signedMessage != null;

  /// Returns whether the popup should be shown that asks for confirmation to share data.
  final bool showConfirmationPopup;

  DisclosurePermissionChoicesOverview({
    required List<DisclosurePermissionStepName> plannedSteps,
    required Map<int, Con<ChoosableDisclosureCredential>> choices,
    required Map<int, bool> isOptional,
    this.signedMessage,
    this.showConfirmationPopup = false,
  }) : super(plannedSteps: plannedSteps, choices: choices, isOptional: isOptional);

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
  final DisclosurePermissionChoices parentState;

  /// DisCon that should be changed.
  final DisCon<DisclosureCredential> discon;

  /// Index of the DisCon within the disclosure candidates ConDisCon.
  final int disconIndex;

  /// Index of the Con within this DisCon that is currently selected.
  final int selectedConIndex;

  DisclosurePermissionChangeChoice({
    required this.parentState,
    required this.discon,
    required this.disconIndex,
    required this.selectedConIndex,
  });

  /// Returns a map with all con indices that are choosable and the corresponding Cons as map value.
  Map<int, Con<ChoosableDisclosureCredential>> get choosableCons => {
        for (int i = 0; i < discon.length; i++)
          if (discon[i].every((cred) => cred is ChoosableDisclosureCredential))
            i: Con(discon[i].whereType<ChoosableDisclosureCredential>())
      };

  /// All template cons within this choice. This also includes choices with combinations of
  /// ChoosableDisclosureCredential and TemplateDisclosureCredentials.
  Map<int, Con<DisclosureCredential>> get templateCons => {
        for (int i = 0; i < discon.length; i++)
          if (discon[i].any((cred) => cred is TemplateDisclosureCredential)) i: discon[i]
      };

  /// The con that is currently selected.
  Con<DisclosureCredential> get selectedCon => discon[selectedConIndex];

  /// Returns whether the current selected con is fully choosable.
  bool get isSelectedChoosable => choosableCons.containsKey(selectedConIndex);

  /// Returns whether this choice is optional.
  bool get isOptional => choosableCons.values.any((con) => con.isEmpty);

  /// Returns whether the given DisclosureCredential is involved in this choice.
  bool contains(DisclosureCredential credential) => discon.any((con) => con.any((cred) => cred == credential));
}

/// State to indicate that the requestDisclosurePermission phase has been finished.
/// This does not necessarily have to mean the total session is completed.
class DisclosurePermissionFinished implements DisclosurePermissionBlocState {}

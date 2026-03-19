import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/schemaless/credential_store.dart";
import "../models/schemaless/schemaless_events.dart";
import "../models/schemaless/session_state.dart";
import "session_state_provider.dart";

class IssueDuringDisclosureState {
  final List<IssuanceStep> steps;
  final List<int> selectedOptionPerStep;
  final int? currentStepIndex;

  /// Non-null when the user just obtained a credential whose attribute values
  /// don't match the requested values. The UI should show a dialog and then
  /// call [IssueDuringDisclosureNotifier.dismissWrongCredentialDialog].
  final Credential? wrongCredentialIssued;

  /// The template descriptor that the wrong credential was supposed to match.
  final CredentialDescriptor? wrongCredentialTemplate;

  const IssueDuringDisclosureState({
    this.steps = const [],
    this.selectedOptionPerStep = const [],
    this.currentStepIndex,
    this.wrongCredentialIssued,
    this.wrongCredentialTemplate,
  });

  bool get isCompleted => steps.isNotEmpty && currentStepIndex == null;
  bool get isSingleStep => steps.length == 1;
  bool get hasWrongCredential => wrongCredentialIssued != null;

  String get explanationKey {
    if (isCompleted) {
      return "disclosure_permission.issue_wizard.explanation_complete";
    }
    return isSingleStep
        ? "disclosure_permission.issue_wizard.explanation_incomplete_single"
        : "disclosure_permission.issue_wizard.explanation_incomplete";
  }
}

class IssueDuringDisclosureNotifier
    extends Notifier<IssueDuringDisclosureState> {
  final int sessionId;

  IssueDuringDisclosureNotifier(this.sessionId);

  @override
  IssueDuringDisclosureState build() {
    ref.listen(sessionStateProvider(sessionId), (previous, next) {
      final session = next.value;
      if (session != null) {
        _updateFromSession(session);
      }
    });

    // Initialize from current session state
    final session = ref.read(sessionStateProvider(sessionId)).value;
    if (session != null) {
      return _buildFromSession(session, const [], const []);
    }
    return const IssueDuringDisclosureState();
  }

  void selectOption(int stepIndex, int optionIndex) {
    final selections = List.of(state.selectedOptionPerStep);
    if (stepIndex < selections.length) {
      selections[stepIndex] = optionIndex;
      state = IssueDuringDisclosureState(
        steps: state.steps,
        selectedOptionPerStep: selections,
        currentStepIndex: state.currentStepIndex,
      );
    }
  }

  void dismissWrongCredentialDialog() {
    state = IssueDuringDisclosureState(
      steps: state.steps,
      selectedOptionPerStep: state.selectedOptionPerStep,
      currentStepIndex: state.currentStepIndex,
    );
  }

  void _updateFromSession(SessionState session) {
    state = _buildFromSession(
      session,
      state.selectedOptionPerStep,
      state.steps,
    );
  }

  static IssueDuringDisclosureState _buildFromSession(
    SessionState session,
    List<int> previousSelections,
    List<IssuanceStep> previousSteps,
  ) {
    final issueDuring = session.disclosurePlan?.issueDuringDislosure;
    // When issueDuringDislosure becomes null (all steps satisfied), retain
    // the previous steps so the completed state can still be displayed.
    final steps = issueDuring?.steps ?? previousSteps;
    final issued = issueDuring?.issuedCredentialIds;

    final selections = List.generate(
      steps.length,
      (i) => i < previousSelections.length ? previousSelections[i] : 0,
    );

    // If issueDuringDislosure is null but we have retained steps,
    // all steps are completed (currentStepIndex = null).
    final currentStepIndex = issueDuring == null && previousSteps.isNotEmpty
        ? null
        : _findCurrentStepIndex(steps, issued);

    // Find the template that the wrong credential was supposed to match.
    final wrongCred = issueDuring?.wrongCredentialIssued;
    CredentialDescriptor? wrongTemplate;
    if (wrongCred != null) {
      for (final step in steps) {
        for (final option in step.options) {
          if (option.credentialId == wrongCred.credentialId) {
            wrongTemplate = option;
            break;
          }
        }
        if (wrongTemplate != null) break;
      }
    }

    return IssueDuringDisclosureState(
      steps: steps,
      selectedOptionPerStep: selections,
      currentStepIndex: currentStepIndex,
      wrongCredentialIssued: wrongCred,
      wrongCredentialTemplate: wrongTemplate,
    );
  }

  static int? _findCurrentStepIndex(
    List<IssuanceStep> steps,
    Map<String, dynamic>? issued,
  ) {
    for (var i = 0; i < steps.length; i++) {
      if (issued == null ||
          issued.isEmpty ||
          !steps[i].options.any(
            (opt) => issued.containsKey(opt.credentialId),
          )) {
        return i;
      }
    }
    return null;
  }
}

final issueDuringDisclosureProvider =
    NotifierProvider.family<
      IssueDuringDisclosureNotifier,
      IssueDuringDisclosureState,
      int
    >((sessionId) => IssueDuringDisclosureNotifier(sessionId));

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/schemaless/session_state.dart";
import "session_state_provider.dart";

class IssueDuringDisclosureState {
  final List<IssuanceStep> steps;
  final List<int> selectedOptionPerStep;
  final int? currentStepIndex;

  const IssueDuringDisclosureState({
    this.steps = const [],
    this.selectedOptionPerStep = const [],
    this.currentStepIndex,
  });

  bool get isCompleted => steps.isNotEmpty && currentStepIndex == null;
  bool get isSingleStep => steps.length == 1;

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
      return _buildFromSession(session, const []);
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

  void _updateFromSession(SessionState session) {
    state = _buildFromSession(session, state.selectedOptionPerStep);
  }

  static IssueDuringDisclosureState _buildFromSession(
    SessionState session,
    List<int> previousSelections,
  ) {
    final steps = session.disclosurePlan?.issueDuringDislosure?.steps ?? [];
    final issued =
        session.disclosurePlan?.issueDuringDislosure?.issuedCredentialIds;

    final selections = List.generate(
      steps.length,
      (i) => i < previousSelections.length ? previousSelections[i] : 0,
    );

    return IssueDuringDisclosureState(
      steps: steps,
      selectedOptionPerStep: selections,
      currentStepIndex: _findCurrentStepIndex(steps, issued),
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

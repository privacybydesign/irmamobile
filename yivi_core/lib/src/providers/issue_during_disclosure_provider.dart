import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/schemaless/credential_store.dart";
import "../models/schemaless/schemaless_events.dart";
import "../models/schemaless/session_state.dart";
import "session_state_provider.dart";

class IssueDuringDisclosureState {
  final List<IssuanceStep> steps;
  final List<int> selectedOptionPerStep;
  final int? currentStepIndex;

  /// Credential ids that have been issued during this session and satisfy
  /// some bundle descriptor in the current plan. Used by the stepper to
  /// render per-card progress within a multi-credential bundle.
  final Set<String> issuedCredentialIds;

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
    this.issuedCredentialIds = const {},
    this.wrongCredentialIssued,
    this.wrongCredentialTemplate,
  });

  /// Returns a copy of this state with selected fields overridden. To clear
  /// nullable fields use the corresponding `clear...` flag.
  IssueDuringDisclosureState copyWith({
    List<IssuanceStep>? steps,
    List<int>? selectedOptionPerStep,
    int? currentStepIndex,
    Set<String>? issuedCredentialIds,
    Credential? wrongCredentialIssued,
    CredentialDescriptor? wrongCredentialTemplate,
    bool clearWrongCredential = false,
  }) {
    return IssueDuringDisclosureState(
      steps: steps ?? this.steps,
      selectedOptionPerStep:
          selectedOptionPerStep ?? this.selectedOptionPerStep,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      issuedCredentialIds: issuedCredentialIds ?? this.issuedCredentialIds,
      wrongCredentialIssued: clearWrongCredential
          ? null
          : (wrongCredentialIssued ?? this.wrongCredentialIssued),
      wrongCredentialTemplate: clearWrongCredential
          ? null
          : (wrongCredentialTemplate ?? this.wrongCredentialTemplate),
    );
  }

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
    if (stepIndex < 0 || stepIndex >= state.steps.length) return;
    final stepOptions = state.steps[stepIndex].options;
    if (optionIndex < 0 || optionIndex >= stepOptions.length) return;
    if (stepIndex >= state.selectedOptionPerStep.length) return;

    final selections = List.of(state.selectedOptionPerStep);
    selections[stepIndex] = optionIndex;
    state = state.copyWith(selectedOptionPerStep: selections);
  }

  void dismissWrongCredentialDialog() {
    state = state.copyWith(clearWrongCredential: true);
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
    final issueDuring = session.disclosurePlan?.issueDuringDisclosure;
    // When issueDuringDisclosure becomes null (all steps satisfied), retain
    // the previous steps so the completed state can still be displayed.
    final steps = issueDuring?.steps ?? previousSteps;
    final issued = issueDuring?.issuedCredentialIds;

    // Carry forward the user's previous selection per step, but clamp against
    // the live step's option count: if the Go side shrinks a step's option
    // list, a stale index would otherwise blow up downstream readers.
    final selections = List<int>.generate(steps.length, (i) {
      if (i >= previousSelections.length) return 0;
      final prev = previousSelections[i];
      final optionCount = steps[i].options.length;
      if (prev < 0 || prev >= optionCount) return 0;
      return prev;
    });

    // If issueDuringDisclosure is null but we have retained steps,
    // all steps are completed (currentStepIndex = null).
    final currentStepIndex = issueDuring == null && previousSteps.isNotEmpty
        ? null
        : findCurrentStepIndex(steps, selections, issued);

    final wrongCred = issueDuring?.wrongCredentialIssued;
    final wrongTemplate = wrongCred == null
        ? null
        : _findTemplate(steps, wrongCred.credentialId);

    return IssueDuringDisclosureState(
      steps: steps,
      selectedOptionPerStep: selections,
      currentStepIndex: currentStepIndex,
      issuedCredentialIds: (issued ?? const <String, dynamic>{}).keys.toSet(),
      wrongCredentialIssued: wrongCred,
      wrongCredentialTemplate: wrongTemplate,
    );
  }

  static CredentialDescriptor? _findTemplate(
    List<IssuanceStep> steps,
    String credentialId,
  ) {
    for (final step in steps) {
      for (final bundle in step.options) {
        for (final descriptor in bundle.credentials) {
          if (descriptor.credentialId == credentialId) return descriptor;
        }
      }
    }
    return null;
  }

  /// Returns the index of the first step whose user-selected bundle is not yet
  /// fully satisfied by [issued]. The user's selection is the source of truth:
  /// if a bundle the user did not pick happens to be satisfied incidentally, we
  /// still consider the step open.
  @visibleForTesting
  static int? findCurrentStepIndex(
    List<IssuanceStep> steps,
    List<int> selections,
    Map<String, dynamic>? issued,
  ) {
    for (var i = 0; i < steps.length; i++) {
      final options = steps[i].options;
      final selectedIndex = i < selections.length ? selections[i] : 0;
      final safeIndex = (selectedIndex >= 0 && selectedIndex < options.length)
          ? selectedIndex
          : 0;
      if (!isBundleFullySatisfied(options[safeIndex], issued)) return i;
    }
    return null;
  }

  /// Returns true iff every credential in [bundle] is present in [issued].
  /// An empty bundle is *not* satisfied — treating it as such would silently
  /// skip the step.
  @visibleForTesting
  static bool isBundleFullySatisfied(
    IssuanceBundle bundle,
    Map<String, dynamic>? issued,
  ) {
    if (bundle.credentials.isEmpty) return false;
    if (issued == null || issued.isEmpty) return false;
    for (final descriptor in bundle.credentials) {
      if (!issued.containsKey(descriptor.credentialId)) return false;
    }
    return true;
  }
}

final issueDuringDisclosureProvider =
    NotifierProvider.family<
      IssueDuringDisclosureNotifier,
      IssueDuringDisclosureState,
      int
    >((sessionId) => IssueDuringDisclosureNotifier(sessionId));

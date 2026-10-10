import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/missing_data_checklist.dart";
import "issue_during_disclosure_provider.dart";
import "session_state_provider.dart";

/// The credential the user went to obtain from the checklist of [sessionId].
class MissingDataFlow {
  final int sessionId;
  final String credentialId;

  const MissingDataFlow({required this.sessionId, required this.credentialId});
}

/// Set while the user is inside an issuance flow that started from the
/// missing data checklist, so those screens can show the band and lead back
/// to the list. Null otherwise.
class MissingDataFlowNotifier extends Notifier<MissingDataFlow?> {
  @override
  MissingDataFlow? build() => null;

  void start({required int sessionId, required String credentialId}) {
    state = MissingDataFlow(sessionId: sessionId, credentialId: credentialId);
  }

  void clear() {
    if (state != null) state = null;
  }

  void clearForSession(int sessionId) {
    if (state?.sessionId == sessionId) state = null;
  }
}

final missingDataFlowProvider =
    NotifierProvider<MissingDataFlowNotifier, MissingDataFlow?>(
      MissingDataFlowNotifier.new,
    );

class MissingDataBandState {
  final String requestorName;
  final MissingDataChecklist checklist;
  final String currentCredentialId;

  const MissingDataBandState({
    required this.requestorName,
    required this.checklist,
    required this.currentCredentialId,
  });
}

/// What the band shows, or null when no checklist flow is active.
final missingDataBandProvider = Provider<MissingDataBandState?>((ref) {
  final flow = ref.watch(missingDataFlowProvider);
  if (flow == null) return null;

  final session = ref.watch(sessionStateProvider(flow.sessionId)).value;
  if (session == null) return null;

  final checklist = MissingDataChecklist.fromWizardState(
    ref.watch(issueDuringDisclosureProvider(flow.sessionId)),
  );
  if (checklist.total == 0) return null;

  return MissingDataBandState(
    requestorName: session.requestor.name,
    checklist: checklist,
    currentCredentialId: flow.credentialId,
  );
});

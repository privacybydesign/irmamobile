import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:rxdart/rxdart.dart";

import "../models/email_code_pointer.dart";
import "../models/schemaless/session_state.dart";
import "../models/session.dart";
import "../models/session_preview.dart";
import "has_in_flight_session_provider.dart";
import "irma_repository_provider.dart";
import "pending_pointer_provider.dart";

/// The request behind the lock screen: a pointer waiting for the PIN (from a
/// QR code or a link), or a session that was already going when the app
/// locked.
class WaitingRequest {
  final SessionPreview preview;

  /// The session started before the app locked: [preview] is its real
  /// requestor (with its trust), not a preview.
  final bool inFlight;

  const WaitingRequest({required this.preview, this.inFlight = false});
}

/// What is waiting behind the lock screen, and as much as is known about it
/// before the PIN (docs/waiting-request-pin-plan.md, 4.1). Null when nothing
/// waits.
final waitingRequestProvider = StreamProvider<WaitingRequest?>((ref) {
  final repo = ref.watch(irmaRepositoryProvider);
  final pointer = ref.watch(pendingPointerProvider);
  switch (pointer) {
    case SessionPointer():
      return repo
          .previewSession(pointer)
          .map((preview) => WaitingRequest(preview: preview));
    case EmailCodePointer():
      return Stream.value(
        WaitingRequest(
          preview: SessionPreview(
            kind: SessionPreviewKind.issuance,
            knowledge: SessionPreviewKnowledge.none,
            email: pointer.email,
          ),
        ),
      );
    case IssueWizardPointer():
      return Stream.value(
        const WaitingRequest(
          preview: SessionPreview(
            kind: SessionPreviewKind.issuance,
            knowledge: SessionPreviewKnowledge.none,
          ),
        ),
      );
    case _:
  }
  if (!ref.watch(hasInFlightSessionProvider)) return Stream.value(null);
  final id = repo.inFlightSessionIds.firstOrNull;
  if (id == null) return Stream.value(null);
  // Before Go's first state there is nothing to show but that something
  // waits.
  return repo
      .getSessionState(id)
      .map(
        (state) => WaitingRequest(
          inFlight: true,
          preview: SessionPreview(
            kind: switch (state.type) {
              SessionType.disclosure => SessionPreviewKind.disclosure,
              SessionType.issuance => SessionPreviewKind.issuance,
              SessionType.signature => SessionPreviewKind.signature,
            },
            knowledge: state.requestor.verified
                ? SessionPreviewKnowledge.registered
                : SessionPreviewKnowledge.unregistered,
            requestor: state.requestor,
          ),
        ),
      )
      .startWith(
        const WaitingRequest(inFlight: true, preview: SessionPreview.unknown),
      );
});

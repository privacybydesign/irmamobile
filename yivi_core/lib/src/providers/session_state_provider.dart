import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:rxdart/rxdart.dart";

import "../data/demo_session_requests.dart";
import "../models/schemaless/schemaless_events.dart";
import "../models/schemaless/session_state.dart";
import "irma_repository_provider.dart";
import "preferences_provider.dart";

final sessionStateProvider = StreamProvider.family<SessionState, int>((
  ref,
  sessionId,
) {
  final repo = ref.watch(irmaRepositoryProvider);
  final states = repo.getSessionState(sessionId);
  if (!(ref.watch(trustDemoServerProvider).value ?? false)) return states;
  return states.map(trustDemoServer);
});

/// Debug menu: whether sessions of the demo IRMA server come from a party
/// Yivi knows. Only in developer mode.
final trustDemoServerProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(irmaRepositoryProvider);
  return Rx.combineLatest2(
    ref.watch(preferencesProvider).getTrustDemoServer(),
    repo.getDeveloperMode(),
    (trust, developerMode) => trust && developerMode,
  );
});

/// [state] as if the demo IRMA server were a party Yivi knows. irmago names
/// a requestor it does not know after its host.
SessionState trustDemoServer(SessionState state) {
  final requestor = state.requestor;
  if (requestor.verified || requestor.name != demoServerHost) return state;
  return state.withRequestor(
    TrustedParty(
      id: "debug.demo-server",
      name: "Yivi demo",
      url: requestor.url,
      parent: requestor.parent,
      verified: true,
      imagePath: requestor.imagePath,
      image: requestor.image,
    ),
  );
}

/// Whether [sessionId] has dispatched a user interaction that's still waiting
/// for the next [SessionState] from Go. Drives the spinner during Gap B and
/// also covers paths where the interaction is dispatched outside SessionScreen
/// (e.g. the OID4VCI auth-code callback).
///
/// Backed by a [Notifier] rather than a [StreamProvider] so the value is
/// available synchronously on the first build of a remount — the underlying
/// [BehaviorSubject] already knows the answer, but a [StreamProvider] would
/// report `AsyncValue.loading()` for one frame and cause a spinner flicker.
class SessionAwaitingInteractionNotifier extends Notifier<bool> {
  final int sessionId;

  SessionAwaitingInteractionNotifier(this.sessionId);

  @override
  bool build() {
    final repo = ref.watch(irmaRepositoryProvider);
    final sub = repo.isSessionAwaitingInteraction(sessionId).listen((v) {
      state = v;
    });
    ref.onDispose(sub.cancel);
    return repo.isSessionAwaitingInteractionNow(sessionId);
  }
}

final sessionAwaitingInteractionProvider =
    NotifierProvider.family<SessionAwaitingInteractionNotifier, bool, int>(
      (sessionId) => SessionAwaitingInteractionNotifier(sessionId),
    );

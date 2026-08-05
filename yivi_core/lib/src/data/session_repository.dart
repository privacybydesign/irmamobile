import "dart:collection";

import "package:rxdart/rxdart.dart";

import "../models/event.dart";
import "../models/schemaless/session_state.dart";
import "../models/schemaless/session_user_interaction.dart";
import "../models/session_events.dart";
import "irma_repository.dart";

/// SessionRepository manages session states.
///
/// It listens for [SessionStateEvent]s and:
/// - Stores the latest [SessionState] per session ID
/// - Emits new session IDs on [newSessionIds] when a previously unseen session appears
/// - Provides per-session state streams via [getSessionState]
class SessionRepository {
  final IrmaRepository repo;

  final _states =
      BehaviorSubject<UnmodifiableMapView<int, SessionState>>.seeded(
        UnmodifiableMapView({}),
      );

  /// Emits session IDs the first time a [SessionStateEvent] is received for them.
  final _newSessionIdsSubject = PublishSubject<int>();

  /// Session IDs whose last user interaction has been dispatched to Go but
  /// for which no follow-up [SessionStateEvent] has yet arrived.
  final _awaitingInteraction = BehaviorSubject<Set<int>>.seeded({});

  /// Session IDs that have been started ([NewSessionEvent]) but have not yet
  /// reached a terminal status. Tracked from the *start* — not the first
  /// `requestPermission` state, which only arrives after a Go round-trip — so
  /// the lock screen can withhold biometric the instant a link starts a session,
  /// before Go replies (issue #654). See [hasInFlightSessionStream].
  final _inFlightSessionIds = BehaviorSubject<Set<int>>.seeded({});

  SessionRepository({required this.repo, required Stream<Event> eventStream}) {
    eventStream.listen(_handleEvent);
  }

  void _handleEvent(Event event) {
    if (event is SessionStateEvent) {
      _handleSessionStateEvent(event);
    } else if (event is NewSessionEvent) {
      // Mark the session in flight from its start, so the lock screen can
      // withhold biometric before Go replies (see [_inFlightSessionIds]).
      _inFlightSessionIds.add(
        Set<int>.from(_inFlightSessionIds.value)..add(event.sessionId),
      );
    } else if (event is SessionUserInteractionEvent &&
        event.type != UserInteractionType.dismiss) {
      _markAwaitingInteraction(event.sessionId);
    }
  }

  void _handleSessionStateEvent(SessionStateEvent event) {
    final state = event.sessionState;
    final prevStates = _states.value;
    final isNew = !prevStates.containsKey(state.id);

    // Count a session exactly once, on its transition into success: any
    // SessionStatus.success (disclosure, issuance or signature) drives the
    // review prompt. Failed/dismissed sessions never count. The prompt itself
    // is gated on an injected store-review service, so this counter growing in
    // the F-Droid build (which injects none) is harmless.
    if (state.status == SessionStatus.success &&
        prevStates[state.id]?.status != SessionStatus.success) {
      repo.preferences.incrementReviewSuccessCount();
    }

    final nextStates = Map<int, SessionState>.from(prevStates);
    nextStates[state.id] = state;
    _states.add(UnmodifiableMapView(nextStates));

    if (isNew) {
      _newSessionIdsSubject.add(state.id);
    }

    // Any new state for this session resolves a pending interaction. Terminal
    // statuses (success/error/dismissed) are also state events, so the entry
    // is cleared on normal session completion as well.
    if (_awaitingInteraction.value.contains(state.id)) {
      final next = Set<int>.from(_awaitingInteraction.value)..remove(state.id);
      _awaitingInteraction.add(next);
    }

    // Mirror Go's session eviction on terminal status: emit the terminal state
    // first so consumers (SessionScreen, integration tests) observe it, then
    // drop the entry from the map. The second emit is filtered out by
    // [getSessionState]'s `containsKey` guard, so subscribers see exactly one
    // terminal emission. Prevents `_states` from growing unboundedly across
    // the app lifetime.
    if (_isTerminalStatus(state.status)) {
      final cleaned = Map<int, SessionState>.from(nextStates)..remove(state.id);
      _states.add(UnmodifiableMapView(cleaned));

      // A terminal session is no longer in flight, so the lock screen may offer
      // biometric again (this is also how the lock-screen ✕ releases it: the
      // dismiss produces a terminal state here).
      if (_inFlightSessionIds.value.contains(state.id)) {
        _inFlightSessionIds.add(
          Set<int>.from(_inFlightSessionIds.value)..remove(state.id),
        );
      }
    }
  }

  static bool _isTerminalStatus(SessionStatus status) =>
      status == SessionStatus.success ||
      status == SessionStatus.error ||
      status == SessionStatus.dismissed;

  void _markAwaitingInteraction(int sessionId) {
    if (_awaitingInteraction.value.contains(sessionId)) return;
    final next = Set<int>.from(_awaitingInteraction.value)..add(sessionId);
    _awaitingInteraction.add(next);
  }

  /// Stream of whether [sessionId] is currently waiting for the next state.
  Stream<bool> isAwaitingInteraction(int sessionId) => _awaitingInteraction
      .stream
      .map((set) => set.contains(sessionId))
      .distinct();

  /// Synchronous read of the current awaiting-interaction state. Used as a
  /// fallback for the first build after a SessionScreen remounts, before the
  /// stream subscription has delivered its seed value.
  bool isAwaitingInteractionNow(int sessionId) =>
      _awaitingInteraction.value.contains(sessionId);

  /// Stream that emits session IDs when a new session is first seen.
  Stream<int> get newSessionIds => _newSessionIdsSubject.stream;

  /// Returns a stream of [SessionState] for the given session ID.
  Stream<SessionState> getSessionState(int sessionId) {
    return _states
        .where((map) => map.containsKey(sessionId))
        .map((map) => map[sessionId]!);
  }

  /// Synchronous lookup of a [SessionState] by its OpenID4VCI `state` value
  /// (the OAuth `state` parameter we minted when starting the auth-code flow).
  /// Returns `null` if no matching in-flight session exists — e.g. the wallet
  /// was restarted between launching the browser and the callback firing.
  SessionState? getCurrentSessionStateByOpenID4VCIState(String sessionState) {
    for (final state in _states.value.values) {
      if (state.openID4VCIState == sessionState) return state;
    }
    return null;
  }

  /// Returns the current [SessionState] for the given session ID, if available.
  SessionState? getCurrentSessionState(int sessionId) {
    return _states.value[sessionId];
  }

  /// Returns the IDs of all sessions currently in the requestPermission state.
  List<int> getActiveSessionIds() {
    return _states.value.entries
        .where((e) => e.value.status == .requestPermission)
        .map((e) => e.key)
        .toList();
  }

  /// Returns whether any session is currently in the requestPermission state.
  /// Optionally excludes a specific session ID from the check.
  bool hasActiveSessions({int? excludeSessionId}) {
    final states = _states.value;
    return states.entries.any(
      (e) => e.key != excludeSessionId && e.value.status == .requestPermission,
    );
  }

  /// Whether any session is currently in flight (started, not yet terminal).
  bool get hasInFlightSession => _inFlightSessionIds.value.isNotEmpty;

  /// The IDs of all sessions currently in flight (started, not yet terminal).
  /// Superset of [getActiveSessionIds]: also covers a session between its start
  /// and Go's first `requestPermission` reply. Used to cancel from the lock
  /// screen — the same set that makes [hasInFlightSession] hide biometric.
  Set<int> get inFlightSessionIds => _inFlightSessionIds.value;

  /// Stream of [hasInFlightSession]. The lock screen watches this to withhold
  /// biometric while a session is in flight — including one a link started just
  /// before the app idle-locked — so it stays PIN-gated (issue #654).
  Stream<bool> get hasInFlightSessionStream =>
      _inFlightSessionIds.map((s) => s.isNotEmpty).distinct();

  Future<void> close() async {
    await Future.wait([
      _states.close(),
      _newSessionIdsSubject.close(),
      _awaitingInteraction.close(),
      _inFlightSessionIds.close(),
    ]);
  }
}

import "dart:collection";

import "package:rxdart/rxdart.dart";

import "../models/event.dart";
import "../models/schemaless/session_state.dart";
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

  SessionRepository({required this.repo, required Stream<Event> eventStream}) {
    eventStream.listen(_handleEvent);
  }

  void _handleEvent(Event event) {
    if (event is SessionStateEvent) {
      _handleSessionStateEvent(event);
    }
  }

  void _handleSessionStateEvent(SessionStateEvent event) {
    final state = event.sessionState;
    final prevStates = _states.value;
    final isNew = !prevStates.containsKey(state.id);

    final nextStates = Map<int, SessionState>.from(prevStates);
    nextStates[state.id] = state;
    _states.add(UnmodifiableMapView(nextStates));

    if (isNew) {
      _newSessionIdsSubject.add(state.id);
    }
  }

  /// Stream that emits session IDs when a new session is first seen.
  Stream<int> get newSessionIds => _newSessionIdsSubject.stream;

  /// Returns a stream of [SessionState] for the given session ID.
  Stream<SessionState> getSessionState(int sessionId) {
    return _states
        .where((map) => map.containsKey(sessionId))
        .map((map) => map[sessionId]!);
  }

  /// Returns a stream of [SessionState] for the given session ID.
  Stream<SessionState> getSessionStateByOpenId4VciState(String sessionState) {
    return _states
        .where(
          (map) =>
              map.values.any((state) => state.oid4VciState == sessionState),
        )
        .map(
          (map) => map.values.firstWhere(
            (state) => state.oid4VciState == sessionState,
          ),
        );
  }

  /// Returns the current [SessionState] for the given session ID, if available.
  SessionState? getCurrentSessionState(int sessionId) {
    return _states.value[sessionId];
  }

  /// Returns whether any session is currently in the requestPermission state.
  /// Optionally excludes a specific session ID from the check.
  Future<bool> hasActiveSessions({int? excludeSessionId}) async {
    final states = _states.value;
    return states.entries.any(
      (e) => e.key != excludeSessionId && e.value.status == .requestPermission,
    );
  }

  Future<void> close() async {
    await Future.wait([_states.close(), _newSessionIdsSubject.close()]);
  }
}

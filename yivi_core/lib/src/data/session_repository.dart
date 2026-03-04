import "dart:collection";
import "dart:math";

import "package:flutter/foundation.dart";
import "package:rxdart/rxdart.dart";

import "../models/attribute.dart";
import "../models/protocol.dart";
import "../models/session.dart";
import "../models/session_events.dart";
import "../models/session_state.dart";
import "../models/translated_value.dart";
import "../util/con_dis_con.dart";
import "irma_repository.dart";

typedef SessionStates = UnmodifiableMapView<int, SessionState>;

class SessionRepository {
  final IrmaRepository repo;

  final _sessionStatesSubject = BehaviorSubject<SessionStates>.seeded(
    SessionStates({}),
  );

  SessionRepository({
    required this.repo,
    required Stream<SessionEvent> sessionEventStream,
  }) {
    // Don't pipe states to the subject directly, because then potential errors are piped to the subject as well.
    sessionEventStream.listen((event) {
      final prevStates = _sessionStatesSubject.value;
      // Calculate the nextState from the previousState by handling the event.
      // In case a new session is created, we create a new session state.
      SessionState? nextState;
      if (prevStates.containsKey(event.sessionID)) {
        final prevState = prevStates[event.sessionID]!;
        if (prevState is IrmaSessionState) {
          nextState = _irmaSessionEventHandler(prevState, event);
        } else if (prevState is OpenID4VciSessionState) {
          nextState = _openid4vciEventHandler(prevState, event);
        }
      } else if (event is NewSessionEvent) {
        nextState = _newSessionState(event);
      }

      // Copy the prevStates into a new map, and add the next state
      final nextStates = Map.of(prevStates);
      if (nextState != null) nextStates[event.sessionID] = nextState;

      _sessionStatesSubject.add(SessionStates(nextStates));
    }, onDone: _sessionStatesSubject.close);
  }

  SessionState _newSessionState(NewSessionEvent event) {
    // Set the url as fallback serverName in case session is canceled before the translated serverName is known.
    RequestorInfo serverName;
    try {
      final url = Uri.parse(event.request.u).host;
      serverName = RequestorInfo(name: TranslatedValue.fromString(url));
    } catch (_) {
      // Error with url will be resolved by bridge, so we don't have to act on that.
      serverName = RequestorInfo(name: const TranslatedValue.empty());
    }
    if (event.request.protocol == Protocol.openid4vci) {
      return OpenID4VciSessionState(
        sessionID: event.sessionID,
        continueOnSecondDevice: event.request.continueOnSecondDevice,
      );
    } else {
      return IrmaSessionState(
        sessionID: event.sessionID,
        clientReturnURL: null,
        continueOnSecondDevice: event.request.continueOnSecondDevice,
        previouslyLaunchedCredentials: event.previouslyLaunchedCredentials,
        status: SessionStatus.initialized,
        serverName: serverName,
        sessionType: event.request.irmaqr,
      );
    }
  }

  OpenID4VciSessionState _openid4vciEventHandler(
    OpenID4VciSessionState prevState,
    SessionEvent event,
  ) {
    if (event is RespondAuthorizationCodeEvent) {
      return prevState;
    }
    debugPrint("Unknown event: $event for state $prevState");
    return prevState;
  }

  IrmaSessionState _irmaSessionEventHandler(
    IrmaSessionState prevState,
    SessionEvent event,
  ) {
    if (event is ContinueToIssuanceEvent) {
      return prevState.copyWith(
        status: SessionStatus.requestIssuancePermission,
        disclosureChoices: ConCon.fromRaw(
          event.disclosureChoices,
          (AttributeIdentifier attrId) => attrId,
        ),
      );
    } else if (event is RespondPermissionEvent) {
      return prevState.copyWith(
        status: SessionStatus.communicating,
        disclosureChoices: event.proceed
            ? ConCon.fromRaw(
                event.disclosureChoices,
                (AttributeIdentifier attrId) => attrId,
              )
            : null,
        dismissed: !event.proceed,
      );
    }

    return prevState;
  }

  SessionState? getCurrentSessionState(int sessionID) =>
      _sessionStatesSubject.value[sessionID];

  Stream<SessionState> getSessionState(int sessionID) => _sessionStatesSubject
      .where((sessionStates) => sessionStates.containsKey(sessionID))
      .map((sessionStates) => sessionStates[sessionID]!);

  Future<SessionState?> getSessionStateByState(String state) async {
    final sessions = await _sessionStatesSubject.first;
    return sessions.values.firstWhere((sessionState) {
      if (sessionState is OpenID4VciSessionState) {
        return sessionState.generateSessionState() == state;
      }
      return false;
    });
  }

  Future<bool> hasActiveSessions() async {
    final sessions = await _sessionStatesSubject.first;
    return sessions.values.any((session) {
      if (session is IrmaSessionState) {
        return session.status == SessionStatus.requestDisclosurePermission;
      }
      return false;
    });
  }

  Uint8List generateSalt() {
    final random = Random.secure();
    final randomBytes = Uint8List(32);
    for (var i = 0; i < randomBytes.length; i++) {
      randomBytes[i] = random.nextInt(256);
    }
    return randomBytes;
  }
}

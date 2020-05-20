import 'package:collection/collection.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stream_transform/stream_transform.dart';

class SessionStates extends UnmodifiableMapView<int, SessionState> {
  SessionStates(Map<int, SessionState> map) : super(map);

  @override
  SessionState operator [](Object sessionID) {
    return super[sessionID] ?? SessionState(sessionID: sessionID as int);
  }
}

class SessionRepository {
  final IrmaRepository repo;
  final Stream<SessionEvent> sessionEventStream;

  final _sessionStatesSubject = BehaviorSubject<SessionStates>();

  SessionRepository({this.repo, this.sessionEventStream}) {
    sessionEventStream.scan<SessionStates>(SessionStates({}), (prevStates, event) async {
      // Calculate the nextState from the previousState by handling the event
      final prevState = prevStates[event.sessionID];
      final nextState = await _eventHandler(prevState, event);

      // Copy the prevStates into a new map, and add the next state
      final nextStates = Map.of(prevStates);
      nextStates[event.sessionID] = nextState;
      return SessionStates(nextStates);
    }).pipe(_sessionStatesSubject);
  }

  Future<SessionState> _eventHandler(SessionState prevState, SessionEvent event) async {
    final irmaConfiguration = await repo.getIrmaConfiguration().first;
    final credentials = await repo.getCredentials().first;

    if (event is NewSessionEvent) {
      return prevState.copyWith(
        clientReturnURL: prevState.clientReturnURL ?? event.request.returnURL,
        continueOnSecondDevice: event.continueOnSecondDevice,
        status: SessionStatus.initialized,
      );
    } else if (event is FailureSessionEvent) {
      return prevState.copyWith(
        status: SessionStatus.error,
        error: event.error,
      );
    } else if (event is StatusUpdateSessionEvent) {
      return prevState.copyWith(
        status: event.status.toSessionStatus(),
      );
    } else if (event is ClientReturnURLSetSessionEvent) {
      return prevState.copyWith(
        clientReturnURL: event.clientReturnURL,
      );
    } else if (event is RequestIssuancePermissionSessionEvent) {
      final processed = ConDisCon.fromRaw<DisclosureCandidate, Attribute>(
        event.disclosuresCandidates,
        (disclosureCandidate) => Attribute.fromCandidate(irmaConfiguration, credentials, disclosureCandidate),
      );
      // We reorder the options in each discon, such that those that first require action
      // (obtaining or refreshing a credential) before they are choosable are last,
      // and those that are immediately choosable are first. Since an option can become
      // choosable in future occurences of this event, this order is not stable, so we
      // choose and remember a sorting order during the first occurrence of this event
      // that we reuse in later occurences.
      final disconOrder = prevState.disconOrder ?? _computeOrder(processed);
      final condiscon = event.satisfiable ? _reorderConDisCon(processed, disconOrder) : processed;
      return prevState.copyWith(
        status: event.disclosuresCandidates?.isEmpty ?? true
            ? SessionStatus.requestIssuancePermission
            : SessionStatus.requestDisclosurePermission,
        serverName: event.serverName,
        satisfiable: event.satisfiable,
        isSignatureSession: false,
        disclosureIndices: List<int>.filled(event.disclosuresCandidates.length, 0),
        disclosureChoices: _initialDisclosureChoices(condiscon),
        disconOrder: disconOrder,
        disclosuresCandidates: condiscon,
        issuedCredentials: event.issuedCredentials
            .map((raw) => Credential.fromRaw(
                  irmaConfiguration: irmaConfiguration,
                  rawCredential: raw,
                ))
            .toList(),
      );
    } else if (event is RequestVerificationPermissionSessionEvent) {
      final processed = ConDisCon.fromRaw<DisclosureCandidate, Attribute>(
        event.disclosuresCandidates,
        (disclosureCandidate) => Attribute.fromCandidate(irmaConfiguration, credentials, disclosureCandidate),
      );
      final disconOrder = prevState.disconOrder ?? _computeOrder(processed);
      final condiscon = event.satisfiable ? _reorderConDisCon(processed, disconOrder) : processed;
      return prevState.copyWith(
        status: SessionStatus.requestDisclosurePermission,
        serverName: event.serverName,
        isSignatureSession: event.isSignatureSession,
        signedMessage: event.signedMessage,
        disclosureIndices: List<int>.filled(event.disclosuresCandidates.length, 0),
        disclosureChoices: _initialDisclosureChoices(condiscon),
        disconOrder: disconOrder,
        disclosuresCandidates: condiscon,
        satisfiable: event.satisfiable,
      );
    } else if (event is ContinueToIssuanceEvent) {
      return prevState.copyWith(
        status: SessionStatus.requestIssuancePermission,
      );
    } else if (event is DisclosureChoiceUpdateSessionEvent) {
      return prevState.copyWith(
        disclosureIndices: List<int>.of(prevState.disclosureIndices)..[event.disconIndex] = event.conIndex,
        disclosureChoices: _updateDisclosureChoices(prevState, event),
      );
    } else if (event is SuccessSessionEvent) {
      return prevState.copyWith(
        status: SessionStatus.success,
      );
    } else if (event is CanceledSessionEvent) {
      return prevState.copyWith(status: SessionStatus.canceled);
    } else if (event is RequestPinSessionEvent) {
      return prevState.copyWith(
        status: SessionStatus.requestPin,
      );
    }

    return prevState;
  }

  ConDisCon<Attribute> _reorderConDisCon(ConDisCon<Attribute> condiscon, List<List<int>> disconOrder) {
    return ConDisCon(condiscon.asMap().keys.map(
          (i) => DisCon(disconOrder[i].map((j) => condiscon[i][j])),
        ));
  }

  // For each discon, computes a list of indices referring to options in the discon,
  // in the order that they should be presented to the user. This function discards
  // inner con's that asks for attributes of which we (1) have no choosable candidate,
  // and (2) new candidates cannot now be obtained using the credential type's IssueURL
  // (as such con's cannot be satisfied by obtaining them during the current session).
  List<List<int>> _computeOrder(ConDisCon<Attribute> condiscon) {
    return condiscon.map((discon) {
      final entries = discon.asMap().entries;
      // first satisfiable con's
      final choosable = entries.fold<List<int>>(
        <int>[],
        (list, con) => con.value.every((attr) => attr.choosable) ? (list..add(con.key)) : list,
      );
      // then unsatisfiable con's containing only choosable or obtainable credentials
      final obtainable = entries.fold<List<int>>(
        <int>[],
        (list, con) => con.value.any((attr) => !attr.choosable) &&
                con.value.every(
                    (attr) => attr.choosable || (attr.credentialInfo.credentialType.issueUrl?.isNotEmpty ?? false))
            ? (list..add(con.key))
            : list,
      );
      // discard unsatisfiable con's containing non-obtainable credentials
      return choosable..addAll(obtainable);
    }).toList();
  }

  Stream<SessionState> getSessionState(int sessionID) {
    return _sessionStatesSubject.map(
      (sessionStates) => sessionStates[sessionID],
    );
  }

  Future<bool> hasActiveSessions() async {
    final sessions = await _sessionStatesSubject.first;
    return sessions.values.any((session) => session.status == SessionStatus.requestDisclosurePermission);
  }

  static ConCon<AttributeIdentifier> _initialDisclosureChoices(ConDisCon<Attribute> list) => ConCon(list.map(
        (discon) => Con(discon[0].map((attr) => AttributeIdentifier.fromAttribute(attr))),
      ));

  // Given session state and a choice event, return an updated list of list of attributes that will be disclosed.
  static ConCon<AttributeIdentifier> _updateDisclosureChoices(
          SessionState state, DisclosureChoiceUpdateSessionEvent event) =>
      ConCon(List<Con<AttributeIdentifier>>.of(state.disclosureChoices)
        ..[event.disconIndex] = Con(state.disclosuresCandidates[event.disconIndex][event.conIndex]
            .map((attr) => AttributeIdentifier.fromAttribute(attr))
            .toList()));
}

import 'package:collection/collection.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:quiver/iterables.dart';
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
      final condiscon = _processCandidates(event.disclosuresCandidates, prevState, irmaConfiguration, credentials);
      final disclosureIndices = prevState.disclosureIndices ?? List<int>.filled(condiscon.length, 0);
      return prevState.copyWith(
        status: event.disclosuresCandidates?.isEmpty ?? true
            ? SessionStatus.requestIssuancePermission
            : SessionStatus.requestDisclosurePermission,
        serverName: event.serverName,
        satisfiable: event.satisfiable,
        isSignatureSession: false,
        disclosureIndices: disclosureIndices,
        disclosureChoices: _choose(disclosureIndices, condiscon),
        disclosuresCandidates: condiscon,
        issuedCredentials: event.issuedCredentials
            .map((raw) => Credential.fromRaw(
                  irmaConfiguration: irmaConfiguration,
                  rawCredential: raw,
                ))
            .toList(),
      );
    } else if (event is RequestVerificationPermissionSessionEvent) {
      final condiscon = _processCandidates(event.disclosuresCandidates, prevState, irmaConfiguration, credentials);
      final disclosureIndices = prevState.disclosureIndices ?? List<int>.filled(condiscon.length, 0);
      return prevState.copyWith(
        status: SessionStatus.requestDisclosurePermission,
        serverName: event.serverName,
        isSignatureSession: event.isSignatureSession,
        signedMessage: event.signedMessage,
        disclosureIndices: disclosureIndices,
        disclosureChoices: _choose(disclosureIndices, condiscon),
        disclosuresCandidates: condiscon,
        satisfiable: event.satisfiable,
      );
    } else if (event is ContinueToIssuanceEvent) {
      return prevState.copyWith(
        status: SessionStatus.requestIssuancePermission,
      );
    } else if (event is DisclosureChoiceUpdateSessionEvent) {
      final indices = List<int>.of(prevState.disclosureIndices)..[event.disconIndex] = event.conIndex;
      return prevState.copyWith(
        disclosureIndices: indices,
        disclosureChoices: _choose(indices, prevState.disclosuresCandidates),
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

  ConDisCon<Attribute> _processCandidates(
    List<List<List<DisclosureCandidate>>> disclosuresCandidates,
    SessionState prevState,
    IrmaConfiguration irmaConfiguration,
    Credentials credentials,
  ) {
    final converted = ConDisCon.fromRaw<DisclosureCandidate, Attribute>(
      disclosuresCandidates,
      (disclosureCandidate) => Attribute.fromCandidate(irmaConfiguration, credentials, disclosureCandidate),
    );
    if (converted.isEmpty) {
      // issuance sessions without attribute disclosure
      return converted;
    }
    final sorted = _sort(converted);
    final prevCondiscon = prevState.disclosuresCandidates;
    if (prevCondiscon?.isEmpty ?? true) {
      // event is called for the first time
      return sorted;
    }
    return ConDisCon(zip<MapEntry<int, DisCon<Attribute>>>(
      [prevCondiscon.asMap().entries, sorted.asMap().entries],
    ).map((discons) {
      // take only cons appearing in both the old and new discons
      final oldCons = discons[1].value.where((con) => _contains(discons[0].value, con)).toList();
      // insert cons added in the new con at the position the user is looking at
      final addedCons = discons[1].value.where((con) => !_contains(discons[0].value, con));
      return DisCon(oldCons..insertAll(prevState.disclosureIndices[discons[0].key], addedCons));
    }));
  }

  // Returns whether or not the con is present in the discon.
  bool _contains(DisCon<Attribute> discon, Con<Attribute> con) {
    return discon.firstWhere(
          (con2) =>
              con.length == con2.length &&
              zip<Attribute>([con, con2]).every((cons) => _attributesEqual(cons[0], cons[1])),
          orElse: () => null,
        ) !=
        null;
  }

  bool _attributesEqual(Attribute left, Attribute right) {
    return left.attributeType.fullId == right.attributeType.fullId &&
        left.value.runtimeType == right.value.runtimeType &&
        left.value.raw == right.value.raw;
  }

  // Returns a new condiscon where in each discon, the cons are reordered as follows:
  // - first all choosable cons,
  // - then all nonchoosable cons in which all nonchoosable attributes are obtainable
  //   (i.e., their IssueURL is not empty)
  // - then the rest (noncoosable cons containing nonobtainable attributes).
  ConDisCon<Attribute> _sort(ConDisCon<Attribute> condiscon) {
    final max = condiscon.map((discon) => discon.length).reduce((a, b) => a > b ? a : b) + 1;
    return ConDisCon(condiscon.map((discon) {
      final l = discon.asMap().entries.toList();
      l.sort((con1, con2) => _sortIndex(max, con1) - _sortIndex(max, con2));
      return DisCon(l.map((con) => con.value));
    }));
  }

  int _sortIndex(int max, MapEntry<int, Con<Attribute>> con) {
    var i = con.key;
    if (con.value.any((attr) => !attr.choosable && (attr.credentialInfo.credentialType.issueUrl?.isEmpty ?? true))) {
      i += 2 * max;
    } else if (con.value.any((attr) => !attr.choosable)) {
      i += max;
    }
    return i;
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

  static ConCon<AttributeIdentifier> _choose(List<int> choices, ConDisCon<Attribute> condiscon) {
    return ConCon(condiscon.asMap().entries.map(
          (discon) => Con(discon.value[choices[discon.key]].map(
            (attr) => AttributeIdentifier.fromAttribute(attr),
          )),
        ));
  }
}

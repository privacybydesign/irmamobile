import 'package:collection/collection.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
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
        clientReturnURL: event.request.returnURL,
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
      final condiscon = processAttributes(
        candidates: event.disclosuresCandidates,
        isSatisfiable: event.satisfiable,
        irmaConfiguration: irmaConfiguration,
        credentials: credentials,
      );
      return prevState.copyWith(
        status: event.disclosuresCandidates?.isEmpty ?? true
            ? SessionStatus.requestIssuancePermission
            : SessionStatus.requestDisclosurePermission,
        serverName: event.serverName,
        satisfiable: event.satisfiable,
        isSignatureSession: false,
        disclosureIndices: List<int>.filled(event.disclosuresCandidates.length, 0),
        disclosureChoices: _initialDisclosureChoices(condiscon),
        disclosuresCandidates: condiscon,
        issuedCredentials: event.issuedCredentials
            .map((raw) => Credential.fromRaw(
                  irmaConfiguration: irmaConfiguration,
                  rawCredential: raw,
                ))
            .toList(),
      );
    } else if (event is RequestVerificationPermissionSessionEvent) {
      final condiscon = processAttributes(
        candidates: event.disclosuresCandidates,
        isSatisfiable: event.satisfiable,
        irmaConfiguration: irmaConfiguration,
        credentials: credentials,
      );
      return prevState.copyWith(
        status: SessionStatus.requestDisclosurePermission,
        serverName: event.serverName,
        isSignatureSession: event.isSignatureSession,
        signedMessage: event.signedMessage,
        disclosureIndices: List<int>.filled(event.disclosuresCandidates.length, 0),
        disclosureChoices: _initialDisclosureChoices(condiscon),
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

  ConDisCon<Attribute> processAttributes({
    List<List<List<DisclosureCandidate>>> candidates,
    bool isSatisfiable,
    IrmaConfiguration irmaConfiguration,
    Credentials credentials,
  }) {
    final condiscon = ConDisCon.fromRaw<DisclosureCandidate, Attribute>(
      candidates,
      (disclosureCandidate) => Attribute.fromCandidate(irmaConfiguration, credentials, disclosureCandidate),
    );
    // Filter out all non-options -- that is, all inner con's containing one or more non-choosable
    // attributes -- until an obtain/refresh button is implemented to make them actionable.
    // TODO: remove this after that has been implemented.
    // If the request is not satisfiable, we do show all non-options so the user knows
    // which credentials to obtain.
    if (!isSatisfiable) {
      return condiscon;
    }
    return ConDisCon(condiscon.map(
      (discon) => DisCon(discon.where((con) => con.every((attr) => attr.choosable))),
    ));
  }

  Stream<SessionState> getSessionState(int sessionID) {
    return _sessionStatesSubject.map(
      (sessionStates) => sessionStates[sessionID],
    );
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

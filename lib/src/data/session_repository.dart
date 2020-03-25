import 'package:collection/collection.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/attributes.dart';
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

    // TODO: Of course this shouldn't be here
    sessionEventStream.listen((event) {
      if (event is RequestIssuancePermissionSessionEvent) {
        repo.bridgedDispatch(RespondPermissionEvent(sessionID: event.sessionID, proceed: true, disclosureChoices: []));
      }
    });
  }

  Future<SessionState> _eventHandler(SessionState prevState, SessionEvent event) async {
    final irmaConfiguration = await repo.getIrmaConfiguration().first;
    final credentials = await repo.getCredentials().first;

    if (event is NewSessionEvent) {
      return prevState.copyWith(
        continueOnSecondDevice: event.continueOnSecondDevice,
        status: SessionStatus.initialized,
      );
    } else if (event is StatusUpdateSessionEvent) {
      return prevState.copyWith(
        status: event.status.toSessionStatus(),
      );
    } else if (event is ClientReturnURLSetSessionEvent) {
      return prevState.copyWith(
        clientReturnURL: event.clientReturnURL,
      );
    } else if (event is RequestVerificationPermissionSessionEvent) {
      final condiscon = ConDisCon.fromRaw<DisclosureCandidate, CredentialAttribute>(
        event.disclosuresCandidates,
        (disclosureCandidate) =>
            CredentialAttribute.fromDisclosureCandidate(irmaConfiguration, credentials, disclosureCandidate),
      );
      return prevState.copyWith(
        status: SessionStatus.requestPermission,
        serverName: event.serverName,
        isSignatureSession: event.isSignatureSession,
        signedMessage: event.signedMessage,
        disclosureIndices: List<int>.filled(event.disclosuresCandidates.length, 0),
        disclosureChoices: _initialDisclosureChoices(condiscon),
        disclosuresCandidates: condiscon,
      );
    } else if (event is DisclosureChoiceUpdateSessionEvent) {
      return prevState.copyWith(
        disclosureIndices: List<int>.of(prevState.disclosureIndices)..insert(event.disconIndex, event.conIndex),
        disclosureChoices: _updateDisclosureChoices(prevState, event),
      );
    } else if (event is SuccessSessionEvent) {
      return prevState.copyWith(
        status: SessionStatus.success,
      );
    }

    return prevState;
  }

  Stream<SessionState> getSessionState(int sessionID) {
    return _sessionStatesSubject.map(
      (sessionStates) => sessionStates[sessionID],
    );
  }

  static ConCon<AttributeIdentifier> _initialDisclosureChoices(ConDisCon<CredentialAttribute> list) => ConCon(list.map(
        (discon) => Con(discon[0].map((attr) => AttributeIdentifier.fromCredentialAttribute(attr))),
      ));

  static ConCon<AttributeIdentifier> _updateDisclosureChoices(
          SessionState prevState, DisclosureChoiceUpdateSessionEvent event) =>
      ConCon(List<Con<AttributeIdentifier>>.of(prevState.disclosureChoices)
        ..[event.disconIndex] = Con(prevState.disclosuresCandidates[event.disconIndex][event.conIndex]
            .map((attr) => AttributeIdentifier.fromCredentialAttribute(attr))
            .toList()));
}

// This code is not null safe yet.
// @dart=2.11

import 'package:collection/collection.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/return_url.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:quiver/iterables.dart';
import 'package:rxdart/rxdart.dart';

// Typedefs are still experimental in Flutter. Therefore, we use inheritance for now.
class SessionStates extends UnmodifiableMapView<int, SessionState> {
  SessionStates(Map<int, SessionState> map) : super(map);
}

class SessionRepository {
  final IrmaRepository repo;

  final _sessionStatesSubject = BehaviorSubject<SessionStates>.seeded(SessionStates({}));

  SessionRepository({this.repo, Stream<SessionEvent> sessionEventStream}) {
    // Don't pipe states to the subject directly, because then potential errors are piped to the subject as well.
    sessionEventStream.listen((event) async {
      final prevStates = _sessionStatesSubject.value;
      // Calculate the nextState from the previousState by handling the event.
      // In case a new session is created, we create a new session state.
      SessionState nextState;
      if (prevStates.containsKey(event.sessionID)) {
        final prevState = prevStates[event.sessionID];
        nextState = await _eventHandler(prevState, event);
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
      serverName = null;
    }
    return SessionState(
      sessionID: event.sessionID,
      clientReturnURL: ReturnURL.parse(event.request.returnURL),
      continueOnSecondDevice: event.request.continueOnSecondDevice,
      inAppCredential: event.inAppCredential,
      status: SessionStatus.initialized,
      serverName: serverName,
      sessionType: event.request.irmaqr,
    );
  }

  Future<SessionState> _eventHandler(SessionState prevState, SessionEvent event) async {
    final irmaConfiguration = await repo.getIrmaConfiguration().first;
    final credentials = await repo.getCredentials().first;

    if (event is FailureSessionEvent) {
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
        clientReturnURL: ReturnURL.parse(event.clientReturnURL),
      );
    } else if (event is PairingRequiredSessionEvent) {
      return prevState.copyWith(
        status: SessionStatus.pairing,
        pairingCode: event.pairingCode,
      );
    } else if (event is RequestIssuancePermissionSessionEvent) {
      try {
        _validateCandidates(event.disclosuresCandidates);
      } on SessionError catch (e) {
        return prevState.copyWith(status: SessionStatus.error, error: e);
      }
      final condiscon = _processCandidates(event.disclosuresCandidates, prevState, irmaConfiguration, credentials);
      // All discons must have an option to choose from. Otherwise the session can never be finished.
      final canBeFinished = condiscon.every((discon) => discon.isNotEmpty);
      List<int> disclosureIndices;
      if (canBeFinished) {
        disclosureIndices = prevState.disclosureIndices ?? List<int>.filled(condiscon.length, 0);
      }
      return prevState.copyWith(
        status: event.disclosuresCandidates?.isEmpty ?? true
            ? SessionStatus.requestIssuancePermission
            : SessionStatus.requestDisclosurePermission,
        serverName: event.serverName,
        satisfiable: event.satisfiable,
        canBeFinished: canBeFinished,
        isSignatureSession: false,
        disclosureIndices: canBeFinished ? disclosureIndices : null,
        disclosureChoices: canBeFinished ? _choose(disclosureIndices, condiscon) : null,
        disclosuresCandidates: condiscon,
        issuedCredentials: event.issuedCredentials
            .map((raw) => Credential.fromRaw(
                  irmaConfiguration: irmaConfiguration,
                  rawCredential: raw,
                ))
            .toList(),
      );
    } else if (event is RequestVerificationPermissionSessionEvent) {
      try {
        _validateCandidates(event.disclosuresCandidates);
      } on SessionError catch (e) {
        return prevState.copyWith(status: SessionStatus.error, error: e);
      }
      final condiscon = _processCandidates(event.disclosuresCandidates, prevState, irmaConfiguration, credentials);
      // All discons must have an option to choose from. Otherwise the session can never be finished.
      final canBeFinished = condiscon.every((discon) => discon.isNotEmpty);
      List<int> disclosureIndices;
      if (canBeFinished) {
        disclosureIndices = prevState.disclosureIndices ?? List<int>.filled(condiscon.length, 0);
      }
      return prevState.copyWith(
        status: SessionStatus.requestDisclosurePermission,
        serverName: event.serverName,
        satisfiable: event.satisfiable,
        canBeFinished: canBeFinished,
        isSignatureSession: event.isSignatureSession,
        signedMessage: event.signedMessage,
        disclosureIndices: canBeFinished ? disclosureIndices : null,
        disclosureChoices: canBeFinished ? _choose(disclosureIndices, condiscon) : null,
        disclosuresCandidates: condiscon,
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
    } else if (event is RespondPermissionEvent) {
      return prevState.copyWith(
        status: SessionStatus.communicating,
      );
    }

    return prevState;
  }

  void _validateCandidates(List<List<List<DisclosureCandidate>>> candidates) {
    for (final discon in candidates) {
      for (final con in discon) {
        for (final cand in con) {
          // We support cand.type consisting of four dot-separated parts; three parts is forbidden here;
          // any other amount of parts is forbidden by irmago before we end up here
          if (cand.type.split('.').length == 3) {
            throw SessionError(
              errorType: 'notSupported',
              info: 'non-attribute disclosures are not supported',
              wrappedError: '"${cand.type}" consists of three parts; four expected',
            );
          }
        }
      }
    }
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
      // use prev discon as basis to preserve order of candidates
      final oldCons = discons[0].value.where((con) => _contains(discons[1].value, con)).toList();
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
    if (con.value.any((attr) => !attr.choosable && attr.credentialInfo.credentialType.issueUrl.isEmpty)) {
      i += 2 * max;
    } else if (con.value.any((attr) => !attr.choosable)) {
      i += max;
    }
    return i;
  }

  Stream<SessionState> getSessionState(int sessionID) {
    return _sessionStatesSubject.where((sessionStates) => sessionStates.containsKey(sessionID)).map(
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

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

import '../models/attribute.dart';
import '../models/credentials.dart';
import '../models/log_entry.dart';
import '../models/protocol.dart';
import '../models/return_url.dart';
import '../models/session.dart';
import '../models/session_events.dart';
import '../models/session_state.dart';
import '../models/translated_value.dart';
import '../util/con_dis_con.dart';
import 'irma_repository.dart';

typedef SessionStates = UnmodifiableMapView<int, SessionState>;

class SessionRepository {
  final IrmaRepository repo;

  final _sessionStatesSubject = BehaviorSubject<SessionStates>.seeded(SessionStates({}));

  SessionRepository({required this.repo, required Stream<SessionEvent> sessionEventStream}) {
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

  OpenID4VciSessionState _openid4vciEventHandler(OpenID4VciSessionState prevState, SessionEvent event) {
    return prevState.copyWith(
      continueOnSecondDevice: true,
      authorizationServer: 'https://google.com',
      serverName: RequestorInfo(name: TranslatedValue({'en': 'Yivi', 'nl': 'Yivi'})),
      credentialInfoList: [
        CredentialTypeInfo(
          issuerName: TranslatedValue({'en': 'Yivi', 'nl': 'Yivi'}),
          name: TranslatedValue({'en': 'Email', 'nl': 'E-mail'}),
          verifiableCredentialType: 'pbdf.pbdf.email',
          attributes: {
            'email': TranslatedValue({'en': 'Email address', 'nl': 'E-mailadres'}),
            'domain': TranslatedValue({'en': 'Email domain', 'nl': 'E-mailadres domein'}),
          },
          credentialFormat: CredentialFormat.sdjwtvc,
        ),
        CredentialTypeInfo(
          issuerName: TranslatedValue({'en': 'Yivi', 'nl': 'Yivi'}),
          name: TranslatedValue({'en': 'Linkedin', 'nl': 'Linkedin'}),
          verifiableCredentialType: 'pbdf.pbdf.linkedin',
          attributes: {
            'firstname': TranslatedValue({'en': 'First name', 'nl': 'Voornaam'}),
            'lastname': TranslatedValue({'en': 'Last name', 'nl': 'Achternaam'}),
            'fullname': TranslatedValue({'en': 'Full name', 'nl': 'Volledige name'}),
          },
          credentialFormat: CredentialFormat.sdjwtvc,
        ),
      ],
    );
    if (event is RequestAuthorizationCodeEvent) {
      return prevState.copyWith(
        serverName: event.serverName,
        authorizationServer: event.authorizationServer,
        credentialInfoList: event.credentialInfoList,
      );
    }
    if (event is FailureSessionEvent) {
      return prevState.copyWith(error: event.error);
    }
    debugPrint('Unknown event: $event for state $prevState');
    return prevState;
  }

  IrmaSessionState _irmaSessionEventHandler(IrmaSessionState prevState, SessionEvent event) {
    if (event is FailureSessionEvent) {
      return prevState.copyWith(
        status: SessionStatus.error,
        error: event.error,
      );
    } else if (event is KeyshareEnrollmentMissingSessionEvent) {
      return prevState.copyWith(
        status: SessionStatus.error,
        error: SessionError(
          errorType: 'keyshareEnrollmentMissing',
          info: 'user not activated at the keyshare server of scheme ${event.schemeManagerID}',
        ),
      );
    } else if (event is KeyshareEnrollmentIncompleteSessionEvent) {
      return prevState.copyWith(
        status: SessionStatus.error,
        error: SessionError(
          errorType: 'keyshareEnrollmentIncomplete',
          info: 'user enrollment incomplete at the keyshare server of scheme ${event.schemeManagerID}',
        ),
      );
    } else if (event is KeyshareEnrollmentDeletedSessionEvent) {
      return prevState.copyWith(
        status: SessionStatus.error,
        error: SessionError(
          errorType: 'keyshareEnrollmentDeleted',
          info: 'user deleted at the keyshare server of scheme ${event.schemeManagerID}',
        ),
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
      // All discons must have an option to choose from. Otherwise the session can never be finished.
      final canBeFinished = event.disclosuresCandidates.every((discon) => discon.isNotEmpty);

      final issuedCredentials = event.issuedCredentials.map((raw) {
        return MultiFormatCredential.fromRawMultiFormatCredential(raw, repo.irmaConfiguration);
      }).toList();

      return prevState.copyWith(
        status: event.disclosuresCandidates.isEmpty
            ? SessionStatus.requestIssuancePermission
            : SessionStatus.requestDisclosurePermission,
        serverName: event.serverName,
        satisfiable: event.satisfiable,
        canBeFinished: canBeFinished,
        isSignatureSession: false,
        disclosuresCandidates: ConDisCon.fromRaw(event.disclosuresCandidates, (DisclosureCandidate dc) => dc),
        issuedCredentials: issuedCredentials,
      );
    } else if (event is RequestVerificationPermissionSessionEvent) {
      try {
        _validateCandidates(event.disclosuresCandidates);
      } on SessionError catch (e) {
        return prevState.copyWith(status: SessionStatus.error, error: e);
      }
      // All discons must have an option to choose from. Otherwise the session can never be finished.
      final canBeFinished = event.disclosuresCandidates.every((discon) => discon.isNotEmpty);

      return prevState.copyWith(
        status: SessionStatus.requestDisclosurePermission,
        serverName: event.serverName,
        satisfiable: event.satisfiable,
        canBeFinished: canBeFinished,
        isSignatureSession: event.isSignatureSession,
        signedMessage: event.signedMessage,
        disclosuresCandidates: ConDisCon.fromRaw(event.disclosuresCandidates, (DisclosureCandidate dc) => dc),
      );
    } else if (event is ContinueToIssuanceEvent) {
      return prevState.copyWith(
        status: SessionStatus.requestIssuancePermission,
        disclosureChoices: ConCon.fromRaw(event.disclosureChoices, (AttributeIdentifier attrId) => attrId),
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
        disclosureChoices:
            event.proceed ? ConCon.fromRaw(event.disclosureChoices, (AttributeIdentifier attrId) => attrId) : null,
        dismissed: !event.proceed,
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

  void handleOpenID4VciAuthCodeCallback(String url) {
    try {
      final uri = Uri.parse(url);
      // state should be the session ID
      final state = int.parse(uri.queryParameters['state']!);
      final code = uri.queryParameters['code']!;

      repo.bridgedDispatch(RespondAuthorizationCodeEvent(
        sessionID: state,
        authorizationCode: code,
        proceed: true,
      ));
    } catch (e) {
      debugPrint('failed to parse openid4vci authorization response');
    }
  }

  SessionState? getCurrentSessionState(int sessionID) => _sessionStatesSubject.value[sessionID];

  Stream<SessionState> getSessionState(int sessionID) => _sessionStatesSubject
      .where((sessionStates) => sessionStates.containsKey(sessionID))
      .map((sessionStates) => sessionStates[sessionID]!);

  Future<bool> hasActiveSessions() async {
    final sessions = await _sessionStatesSubject.first;
    return sessions.values.any((session) {
      if (session is IrmaSessionState) {
        return session.status == SessionStatus.requestDisclosurePermission;
      }
      return false;
    });
  }
}

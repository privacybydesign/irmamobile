import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:irmamobile/src/data/irma_bridge.dart';
import 'package:irmamobile/src/data/mock_data.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/credential_events.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/enrollment_events.dart';
import 'package:irmamobile/src/models/event.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/native_events.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:rxdart/rxdart.dart';

typedef EventUnmarshaller = Event Function(Map<String, dynamic>);

class IrmaMockBridge extends IrmaBridge {
  static final _irmaConfiguration =
      IrmaConfigurationEvent.fromJson(jsonDecode(irmaConfigurationEventJson) as Map<String, dynamic>).irmaConfiguration;

  final List<RawCredential> _storedCredentials = [];
  final _receivedEvents = BehaviorSubject<Event>();

  IrmaMockBridge();

  Future<void> close() => _receivedEvents.close();

  @override
  void dispatch(Event event) {
    _receivedEvents.add(event);
    if (event is AppReadyEvent) {
      addEvent(IrmaConfigurationEvent(irmaConfiguration: _irmaConfiguration));
      addEvent(CredentialsEvent(credentials: _storedCredentials));
    } else if (event is EnrollEvent) {
      // For example respond with IrmaRepository.get().dispatch(EnrollmentSuccessEvent(...))
    }
  }

  Event _constructRequestVerificationPermissionEvent(
    int sessionId,
    Map<String, String?> requestedAttributes,
    List<RawCredential> credentials,
  ) {
    // Group all candidates on credential id.
    final groupedCandidates = groupBy<MapEntry<String, String?>, String>(
        requestedAttributes.entries, (entry) => entry.key.split('.').take(3).join('.')).entries;

    // Expand candidates with concrete options, based on the given credentials.
    final disclosureCandidates = groupedCandidates.map((group) {
      final List<List<DisclosureCandidate>> discon = [];
      // Look through all credentials for attributes that match the request.
      for (RawCredential c in credentials) {
        if (c.fullId == group.key &&
            group.value.every((attr) => attr.value == null || attr.value == c.attributes[attr.key]!.translate(''))) {
          discon.add(group.value
              .map((attr) => DisclosureCandidate(
                    type: attr.key,
                    value: c.attributes[attr.key] ?? const TranslatedValue.empty(),
                    credentialHash: c.hash,
                  ))
              .toList());
        }
      }

      // Add placeholder candidate if (additional) options can be added using issuance-in-disclosure.
      if (discon.isEmpty || !_irmaConfiguration.credentialTypes[group.key]!.isSingleton) {
        discon.add(group.value
            .map((e) => DisclosureCandidate(
                  type: e.key,
                  value: e.value == null ? const TranslatedValue.empty() : TranslatedValue.fromStringWithRaw(e.value!),
                ))
            .toList());
      }
      return discon;
    }).toList();

    return RequestVerificationPermissionSessionEvent(
      sessionID: sessionId,
      serverName: RequestorInfo(name: TranslatedValue.fromString('test')),
      // Check whether all credentials have been issued to test issuance-in-disclosure.
      satisfiable: disclosureCandidates.every(
          (discon) => discon.any((con) => con.every((candidate) => candidate.credentialHash?.isNotEmpty ?? false))),
      disclosuresCandidates: disclosureCandidates,
      isSignatureSession: false,
    );
  }

  /// Mock a disclosure session of the given candidates. The given candidates are expanded
  /// to condiscon in such a way that all attributes from the same credentials are being
  /// clustered in the inner con of a condiscon.
  @visibleForTesting
  Future<void> mockDisclosureSession(Map<String, String?> candidates) => () async* {
        final newSessionEvent = NewSessionEvent(request: SessionPointer(irmaqr: 'disclosing'));
        yield newSessionEvent;
        final sessionId = newSessionEvent.sessionID;
        yield StatusUpdateSessionEvent(
          sessionID: sessionId,
          action: 'disclosing',
          status: 'communicating',
        );
        yield StatusUpdateSessionEvent(
          sessionID: sessionId,
          action: 'disclosing',
          status: 'connected',
        );

        yield _constructRequestVerificationPermissionEvent(sessionId, candidates, _storedCredentials);

        // Keep updating verification permission when new credentials have been added, until user has responded.
        yield* events
            .takeUntil(_receivedEvents.where((e) => e is RespondPermissionEvent && e.sessionID == sessionId))
            .where((e) => e is CredentialsEvent)
            .cast<CredentialsEvent>()
            .map((e) => _constructRequestVerificationPermissionEvent(sessionId, candidates, e.credentials));

        if ((_receivedEvents.value as RespondPermissionEvent).proceed) {
          yield SuccessSessionEvent(sessionID: sessionId);
        } else {
          yield CanceledSessionEvent(sessionID: sessionId);
        }
      }()
          .forEach(addEvent);

  /// Mock an issuing session of the given credentials.
  @visibleForTesting
  Future<void> mockIssuanceSession(List<RawCredential> credentials) => () async* {
        final newSessionEvent = NewSessionEvent(request: SessionPointer(irmaqr: 'issuing'));
        yield newSessionEvent;
        final sessionId = newSessionEvent.sessionID;
        yield StatusUpdateSessionEvent(
          sessionID: sessionId,
          action: 'issuing',
          status: 'communicating',
        );
        yield PairingRequiredSessionEvent(
          sessionID: sessionId,
          pairingCode: '1234',
        );
        yield StatusUpdateSessionEvent(
          sessionID: sessionId,
          action: 'issuing',
          status: 'connected',
        );
        yield RequestIssuancePermissionSessionEvent(
          sessionID: sessionId,
          serverName: RequestorInfo(name: TranslatedValue.fromString('test')),
          satisfiable: true,
          issuedCredentials: credentials,
        );

        // Wait for the RespondPermissionEvent to come.
        final permissionEvent = await _receivedEvents
            .firstWhere((e) => e is RespondPermissionEvent && e.sessionID == sessionId) as RespondPermissionEvent;

        if (permissionEvent.proceed) {
          yield SuccessSessionEvent(sessionID: sessionId);
          _storedCredentials.addAll(credentials);
          yield CredentialsEvent(credentials: _storedCredentials);
        } else {
          yield CanceledSessionEvent(sessionID: sessionId);
        }
      }()
          .forEach(addEvent);
}

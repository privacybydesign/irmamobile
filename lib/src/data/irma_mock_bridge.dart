import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:irmamobile/src/data/irma_bridge.dart';
import 'package:irmamobile/src/data/mock_data.dart';
import 'package:irmamobile/src/models/attribute_value.dart';
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
  final _sessionEventsSubject = BehaviorSubject<SessionEvent>();

  IrmaMockBridge();

  Future<void> close() => _sessionEventsSubject.close();

  @override
  void dispatch(Event event) {
    if (event is AppReadyEvent) {
      addEvent(IrmaConfigurationEvent(irmaConfiguration: _irmaConfiguration));
      addEvent(CredentialsEvent(credentials: _storedCredentials));
    } else if (event is EnrollEvent) {
      // For example respond with IrmaRepository.get().dispatch(EnrollmentSuccessEvent(...))
    } else if (event is SessionEvent) {
      _sessionEventsSubject.add(event);
    } else {
      throw UnsupportedError('No mocked behaviour implemented for ${event.runtimeType}');
    }
  }

  Event _constructRequestVerificationPermissionEvent(
    int sessionId,
    List<Map<String, String?>> concon,
    List<RawCredential> credentials,
  ) {
    // Expand candidates with concrete options, based on the given credentials.
    final disclosureCandidates = concon.map((con) {
      // For mocking simplicity we assume all attributes in an inner con are from the same credential.
      assert(con.isNotEmpty);
      final credentialId = con.keys.first.split('.').take(3).join('.');
      assert(con.keys.every((attrType) => attrType.startsWith('$credentialId.')));

      final List<List<DisclosureCandidate>> disconCandidates = [];
      // Look through all credentials for attributes that match the request.
      for (final RawCredential c in credentials) {
        if (c.fullId == credentialId &&
            con.entries
                .every((attr) => attr.value == null || attr.value == TextValue.fromRaw(c.attributes[attr.key]!).raw)) {
          disconCandidates.add(con.entries
              .map((attr) => DisclosureCandidate(
                    type: attr.key,
                    value: c.attributes[attr.key] ?? const TranslatedValue.empty(),
                    credentialHash: c.hash,
                  ))
              .toList());
        }
      }

      // Add placeholder candidate if (additional) options can be added using issuance-in-disclosure.
      if (disconCandidates.isEmpty || !_irmaConfiguration.credentialTypes[credentialId]!.isSingleton) {
        disconCandidates.add(con.entries
            .map((attr) => DisclosureCandidate(
                  type: attr.key,
                  value: attr.value == null
                      ? const TranslatedValue.empty()
                      : TextValue(translated: TranslatedValue.fromString(attr.value!), raw: attr.value!).toRaw(),
                ))
            .toList());
      }
      return disconCandidates;
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

  /// Mock a disclosure session with the given concon. For now, this function does not support full
  /// condiscon requests. Inner cons should be given as a map, i.e. {"irma-demo.some.attribute.type": "value"}.
  /// When requesting null, any attribute value is accepted.
  @visibleForTesting
  Future<void> mockDisclosureSession(int sessionId, List<Map<String, String?>> concon) => () async* {
        await _sessionEventsSubject.firstWhere((event) => event is NewSessionEvent && event.sessionID == sessionId);
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

        yield _constructRequestVerificationPermissionEvent(sessionId, concon, _storedCredentials);

        // Keep updating verification permission when new credentials have been added, until user has responded.
        yield* events
            .takeUntil(_sessionEventsSubject.where((e) => e is RespondPermissionEvent && e.sessionID == sessionId))
            .where((e) => e is CredentialsEvent)
            .cast<CredentialsEvent>()
            .map((e) => _constructRequestVerificationPermissionEvent(sessionId, concon, e.credentials));

        if ((_sessionEventsSubject.value as RespondPermissionEvent).proceed) {
          yield SuccessSessionEvent(sessionID: sessionId);
        } else {
          yield CanceledSessionEvent(sessionID: sessionId);
        }
      }()
          .forEach(addEvent);

  /// Mock an issuing session of the given list credentials. Credentials should be given by
  /// specifying a text value for each attribute in a map.
  @visibleForTesting
  Future<void> mockIssuanceSession(int sessionId, List<Map<String, TextValue>> credentials) => () async* {
        await _sessionEventsSubject.firstWhere((event) => event is NewSessionEvent && event.sessionID == sessionId);
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

        // Convert given credentials to RawCredentials.
        final now = DateTime.now();
        final issuedCredentials = credentials.map((attrs) {
          // All attributes in a credential should be known in the configuration.
          assert(attrs.entries
                  .map((attr) => _irmaConfiguration.attributeTypes[attr.key]!.fullCredentialId)
                  .toSet()
                  .length ==
              1);
          final attributeType = _irmaConfiguration.attributeTypes[attrs.keys.first]!;
          return RawCredential(
            schemeManagerId: attributeType.schemeManagerId,
            issuerId: attributeType.issuerId,
            id: attributeType.credentialTypeId,
            signedOn: now.microsecondsSinceEpoch ~/ 1000,
            expires: now.add(const Duration(days: 365)).microsecondsSinceEpoch ~/ 1000,
            attributes: attrs.map((key, value) => MapEntry(key, value.toRaw())),
            hash: 'session-$sessionId', // Use the session id as a dummy hash to make it unique and predicable.
            revoked: false,
            revocationSupported: false,
          );
        }).toList();

        yield RequestIssuancePermissionSessionEvent(
          sessionID: sessionId,
          serverName: RequestorInfo(name: TranslatedValue.fromString('test')),
          satisfiable: true,
          issuedCredentials: issuedCredentials,
        );

        // Wait for the RespondPermissionEvent to come.
        final permissionEvent = await _sessionEventsSubject
            .firstWhere((e) => e is RespondPermissionEvent && e.sessionID == sessionId) as RespondPermissionEvent;

        if (permissionEvent.proceed) {
          yield SuccessSessionEvent(sessionID: sessionId);
          _storedCredentials.addAll(issuedCredentials);
          yield CredentialsEvent(credentials: _storedCredentials);
        } else {
          yield CanceledSessionEvent(sessionID: sessionId);
        }
      }()
          .forEach(addEvent);
}

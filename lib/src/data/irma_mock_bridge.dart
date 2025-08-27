import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../models/attribute.dart';
import '../models/attribute_value.dart';
import '../models/credential_events.dart';
import '../models/credentials.dart';
import '../models/enrollment_events.dart';
import '../models/event.dart';
import '../models/irma_configuration.dart';
import '../models/log_entry.dart';
import '../models/native_events.dart';
import '../models/session.dart';
import '../models/session_events.dart';
import '../models/translated_value.dart';
import 'irma_bridge.dart';
import 'mock_data.dart';

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
    List<List<Map<String, String?>>> condiscon,
    List<RawCredential> credentials,
    String? signedMessage,
  ) {
    // Expand candidates with concrete options, based on the given credentials.
    final disclosureCandidates = condiscon
        .map((discon) => discon.expand((con) {
              List<List<DisclosureCandidate>> disconCandidates = [];

              // Check whether it concerns an optional disjunction.
              if (con.isEmpty) {
                disconCandidates.add([]);
                return disconCandidates;
              }

              final groupedAttrs = groupBy<String, String>(con.keys, (attrId) => attrId.split('.').take(3).join('.'));
              // A con should contain at most one non-singleton credential.
              final nonSingletonCredIds =
                  groupedAttrs.keys.where((credId) => !_irmaConfiguration.credentialTypes[credId]!.isSingleton);
              assert(nonSingletonCredIds.length <= 1);

              // Look through all credentials for attributes that match the request.
              for (final entry in groupedAttrs.entries) {
                final List<List<DisclosureCandidate>> credCandidates = [];
                for (final RawCredential c in credentials) {
                  if (c.fullId == entry.key &&
                      entry.value.every((attrId) =>
                          con[attrId] == null || con[attrId] == TextValue.fromRaw(c.attributes[attrId]!).raw)) {
                    credCandidates.add(entry.value
                        .map((attrId) => DisclosureCandidate(
                              type: attrId,
                              value: c.attributes[attrId] ?? const TranslatedValue.empty(),
                              credentialHash: c.hash,
                            ))
                        .toList());
                  }
                }
                // Add all candidates for the current credential to the disconCandidates.
                if (disconCandidates.isEmpty) {
                  disconCandidates.addAll(credCandidates);
                } else if (credCandidates.isNotEmpty) {
                  disconCandidates = disconCandidates
                      .expand((conCandidate) => credCandidates.map((cc) => [...conCandidate, ...cc]))
                      .toList();
                }
              }

              // Fill all missing disclosure candidates with placeholders.
              disconCandidates = disconCandidates
                  .map((conCandidates) => con.entries
                      .map((entry) => conCandidates.firstWhere((candidate) => candidate.type == entry.key,
                          orElse: () => _generatePlaceholderCandidate(entry.key, entry.value)))
                      .toList())
                  .toList();

              // If we already found candidates and all credentials are singletons, then we
              // don't have to add placeholder candidates.
              if (disconCandidates.isNotEmpty && nonSingletonCredIds.isEmpty) {
                return disconCandidates;
              }

              // Pre-generate placeholder candidates.
              final placeholderCandidates = groupedAttrs.map(
                (credId, attrIds) => MapEntry(
                    credId, attrIds.map((attrId) => _generatePlaceholderCandidate(attrId, con[attrId])).toList()),
              );

              if (disconCandidates.isEmpty) {
                return [placeholderCandidates.values.flattened.toList()];
              }

              // Add placeholder to add an extra instance of the non singleton credential type if the placeholder
              // is not there yet already.
              final nonSingletonCandidate = disconCandidates.first
                  .firstWhere((candidate) => candidate.type.startsWith('${nonSingletonCredIds.first}.'));
              if (nonSingletonCandidate.credentialHash.isNotEmpty) {
                final placeholderCandidate = disconCandidates.first
                    .map((attr) => placeholderCandidates[nonSingletonCredIds.first]!
                        .firstWhere((phAttr) => phAttr.type == attr.type, orElse: () => attr))
                    .toList();
                return [...disconCandidates, placeholderCandidate];
              }

              return disconCandidates;
            }))
        .map((discon) {
      // All choosable candidates should come first in the list.
      final choosableCandidates = discon.where((con) => con.isEmpty || con[0].credentialHash.isNotEmpty);
      final templateCandidates = discon.where((con) => con.isNotEmpty && con[0].credentialHash.isEmpty);
      return [...choosableCandidates, ...templateCandidates];
    }).toList();

    return RequestVerificationPermissionSessionEvent(
      sessionID: sessionId,
      serverName: RequestorInfo(name: TranslatedValue.fromString('test')),
      // Check whether all credentials have been issued to test issuance-in-disclosure.
      satisfiable: disclosureCandidates
          .every((discon) => discon.any((con) => con.every((candidate) => candidate.credentialHash.isNotEmpty))),
      disclosuresCandidates: disclosureCandidates,
      isSignatureSession: signedMessage != null,
      signedMessage: signedMessage,
    );
  }

  DisclosureCandidate _generatePlaceholderCandidate(String type, String? value) => DisclosureCandidate(
        type: type,
        value: value == null
            ? const TranslatedValue.empty()
            : TextValue(translated: TranslatedValue.fromString(value), raw: value).toRaw(),
      );

  /// Mock a disclosure session with the given condiscon.
  /// Inner cons should be given as a map, i.e. {"irma-demo.some.attribute.type": "value"}.
  /// When requesting null, any attribute value is accepted.
  @visibleForTesting
  Future<void> mockDisclosureSession(
    int sessionId,
    List<List<Map<String, String?>>> condiscon, {
    String? signedMessage,
  }) =>
      () async* {
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

        yield _constructRequestVerificationPermissionEvent(sessionId, condiscon, _storedCredentials, signedMessage);

        // Keep updating verification permission when new credentials have been added, until user has responded.
        yield* events
            .takeUntil(_sessionEventsSubject.where((e) => e is RespondPermissionEvent && e.sessionID == sessionId))
            .where((e) => e is CredentialsEvent)
            .cast<CredentialsEvent>()
            .map((e) =>
                _constructRequestVerificationPermissionEvent(sessionId, condiscon, e.credentials, signedMessage));

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
  Future<void> mockIssuanceSession(
    int sessionId,
    List<Map<String, TextValue>> credentials, {
    Duration validity = const Duration(days: 365),
    bool revoked = false,
  }) =>
      () async* {
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
        final issuedCredentials = credentials.mapIndexed((i, attrs) {
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
            signedOn: now.millisecondsSinceEpoch ~/ 1000,
            expires: now.add(validity).millisecondsSinceEpoch ~/ 1000,
            attributes: attrs.map((key, value) => MapEntry(key, value.toRaw())),
            hash: 'session-$sessionId-$i', // Use the session id as a dummy hash to make it unique and predicable.
            revoked: revoked,
            revocationSupported: revoked,
            format: CredentialFormat.idemix,
            instanceCount: 0,
          );
        }).toList();

        yield RequestIssuancePermissionSessionEvent(
          sessionID: sessionId,
          serverName: RequestorInfo(name: TranslatedValue.fromString('test')),
          satisfiable: true,
          issuedCredentials: issuedCredentials.map(RawMultiFormatCredential.fromRawCredential).toList(),
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

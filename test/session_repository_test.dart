// This code is not null safe yet.
// @dart=2.11

import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/data/irma_mock_bridge.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:irmamobile/src/models/translated_value.dart';

void main() {
  IrmaRepository repo;
  IrmaMockBridge mockBridge;

  setUp(() {
    mockBridge = IrmaMockBridge();
    repo = IrmaRepository(client: mockBridge);
  });
  tearDown(() async {
    await mockBridge.close();
    await repo.close();
  });

  test('issuance-in-disclosure', () async {
    mockBridge.mockDisclosureSession(42, {'irma-demo.IRMATube.member.id': null});
    repo.dispatch(NewSessionEvent(sessionId: 42, request: SessionPointer(irmaqr: 'disclosing')), isBridgedEvent: true);

    final disclosureSessionStream = repo.getSessionState(42).asBroadcastStream();
    SessionState disclosureSession = await disclosureSessionStream
        .firstWhere((session) => session.status == SessionStatus.requestDisclosurePermission);
    expect(disclosureSession.canBeFinished, true);
    expect(disclosureSession.satisfiable, false);
    expect(disclosureSession.canDisclose, false);
    expect(disclosureSession.isSignatureSession, false);
    expect(disclosureSession.signedMessage, null);
    expect(disclosureSession.clientReturnURL, null);
    expect(disclosureSession.disclosureChoices.length, 1);
    expect(disclosureSession.disclosureChoices[0].length, 1);
    expect(disclosureSession.disclosureChoices[0][0].type, 'irma-demo.IRMATube.member.id');
    expect(disclosureSession.disclosureChoices[0][0].credentialHash, '');
    expect(disclosureSession.disclosureIndices, [0]);

    mockBridge.mockIssuanceSession(43, [
      {
        'irma-demo.IRMATube.member.id': TranslatedValue.fromStringWithRaw('12345'),
        'irma-demo.IRMATube.member.type': TranslatedValue.fromStringWithRaw('member'),
      }
    ]);
    repo.dispatch(NewSessionEvent(sessionId: 43, request: SessionPointer(irmaqr: 'issuing')), isBridgedEvent: true);
    final issuanceSessionStream = repo.getSessionState(43).asBroadcastStream();

    // Check whether the pairing status is being triggered.
    await issuanceSessionStream.firstWhere((session) => session.status == SessionStatus.pairing);

    final issuanceSession =
        await issuanceSessionStream.firstWhere((session) => session.status == SessionStatus.requestIssuancePermission);
    expect(issuanceSession.sessionID, 43);
    expect(issuanceSession.status, SessionStatus.requestIssuancePermission);
    expect(issuanceSession.canBeFinished, true);
    expect(issuanceSession.satisfiable, true);
    expect(issuanceSession.isSignatureSession, false);
    expect(issuanceSession.signedMessage, null);
    expect(issuanceSession.clientReturnURL, null);
    expect(issuanceSession.disclosureChoices, []);
    expect(issuanceSession.disclosureIndices, []);
    repo.dispatch(RespondPermissionEvent(sessionID: 43, proceed: true, disclosureChoices: [[]]), isBridgedEvent: true);

    await issuanceSessionStream.firstWhere((session) => session.status == SessionStatus.success);

    disclosureSession = await disclosureSessionStream.firstWhere((session) => session.satisfiable);
    expect(disclosureSession.satisfiable, true);
    expect(disclosureSession.status, SessionStatus.requestDisclosurePermission);
    expect(disclosureSession.canDisclose, true);
    expect(disclosureSession.disclosureChoices.length, 1);
    expect(disclosureSession.disclosureChoices[0].length, 1);
    expect(disclosureSession.disclosureChoices[0][0].type, 'irma-demo.IRMATube.member.id');
    expect(disclosureSession.disclosureChoices[0][0].credentialHash, 'session-43');
    expect(disclosureSession.disclosureIndices, [0]);
    repo.dispatch(
      RespondPermissionEvent(sessionID: 42, proceed: true, disclosureChoices: disclosureSession.disclosureChoices),
      isBridgedEvent: true,
    );

    await disclosureSessionStream.firstWhere((session) => session.status == SessionStatus.success);
  });

  test('issuance-in-disclosure-using-specific-attributes', () async {
    mockBridge.mockDisclosureSession(42, {'irma-demo.IRMATube.member.id': '123'});
    repo.dispatch(NewSessionEvent(sessionId: 42, request: SessionPointer(irmaqr: 'disclosing')), isBridgedEvent: true);

    // The disclosure session should not be satisfiable yet.
    final disclosureSessionStream = repo.getSessionState(42).asBroadcastStream();
    SessionState disclosureSession = await disclosureSessionStream
        .firstWhere((session) => session.status == SessionStatus.requestDisclosurePermission);
    expect(disclosureSession.canBeFinished, true);
    expect(disclosureSession.satisfiable, false);
    expect(disclosureSession.canDisclose, false);
    expect(disclosureSession.disclosureChoices.length, 1);
    expect(disclosureSession.disclosureChoices[0].length, 1);
    expect(disclosureSession.disclosureChoices[0][0].type, 'irma-demo.IRMATube.member.id');
    expect(disclosureSession.disclosureChoices[0][0].credentialHash, '');

    // Start an issuance session to get a non-matching credential.
    mockBridge.mockIssuanceSession(43, [
      {
        'irma-demo.IRMATube.member.id': TranslatedValue.fromStringWithRaw('124'),
        'irma-demo.IRMATube.member.type': TranslatedValue.fromStringWithRaw('member'),
      }
    ]);
    repo.dispatch(NewSessionEvent(sessionId: 43, request: SessionPointer(irmaqr: 'issuing')), isBridgedEvent: true);

    // Give permission to accept the non-matching credential.
    final firstIssuanceSessionStream = repo.getSessionState(43).asBroadcastStream();
    await firstIssuanceSessionStream.firstWhere((session) => session.status == SessionStatus.requestIssuancePermission);
    repo.dispatch(RespondPermissionEvent(sessionID: 43, proceed: true, disclosureChoices: [[]]), isBridgedEvent: true);
    await firstIssuanceSessionStream.firstWhere((session) => session.status == SessionStatus.success);

    // The disclosure session should still not be satisfiable.
    disclosureSession = await disclosureSessionStream
        .firstWhere((session) => session.status == SessionStatus.requestDisclosurePermission);
    expect(disclosureSession.canBeFinished, true);
    expect(disclosureSession.satisfiable, false);
    expect(disclosureSession.canDisclose, false);
    expect(disclosureSession.disclosureChoices.length, 1);
    expect(disclosureSession.disclosureChoices[0].length, 1);
    expect(disclosureSession.disclosureChoices[0][0].type, 'irma-demo.IRMATube.member.id');
    expect(disclosureSession.disclosureChoices[0][0].credentialHash, '');

    // Start a second issuance session to get the right credential.
    mockBridge.mockIssuanceSession(44, [
      {
        'irma-demo.IRMATube.member.id': TranslatedValue.fromStringWithRaw('123'),
        'irma-demo.IRMATube.member.type': TranslatedValue.fromStringWithRaw('member'),
      }
    ]);
    repo.dispatch(NewSessionEvent(sessionId: 44, request: SessionPointer(irmaqr: 'issuing')), isBridgedEvent: true);
    final secondIssuanceSessionStream = repo.getSessionState(44).asBroadcastStream();

    // Give permission to accept second credential.
    await secondIssuanceSessionStream
        .firstWhere((session) => session.status == SessionStatus.requestIssuancePermission);
    repo.dispatch(RespondPermissionEvent(sessionID: 44, proceed: true, disclosureChoices: [[]]), isBridgedEvent: true);
    await secondIssuanceSessionStream.firstWhere((session) => session.status == SessionStatus.success);

    // Check whether the disclosure session can be finished now.
    disclosureSession = await disclosureSessionStream
        .firstWhere((session) => session.status == SessionStatus.requestDisclosurePermission);
    expect(disclosureSession.satisfiable, true);
    expect(disclosureSession.canDisclose, true);
    expect(disclosureSession.disclosureChoices.length, 1);
    expect(disclosureSession.disclosureChoices[0].length, 1);
    expect(disclosureSession.disclosureChoices[0][0].type, 'irma-demo.IRMATube.member.id');
    expect(disclosureSession.disclosureChoices[0][0].credentialHash, 'session-44');
    expect(disclosureSession.disclosureIndices, [0]);
    repo.dispatch(
      RespondPermissionEvent(sessionID: 42, proceed: true, disclosureChoices: disclosureSession.disclosureChoices),
      isBridgedEvent: true,
    );

    await disclosureSessionStream.firstWhere((session) => session.status == SessionStatus.success);
  });
}

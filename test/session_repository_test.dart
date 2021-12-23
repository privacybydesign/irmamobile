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

    SessionState disclosureSession = await repo
        .getSessionState(42)
        .firstWhere((session) => session.status == SessionStatus.requestDisclosurePermission);
    expect(disclosureSession.sessionID, 42);
    expect(disclosureSession.status, SessionStatus.requestDisclosurePermission);
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

    // Check whether the pairing status is being triggered.
    await repo.getSessionState(43).firstWhere((session) => session.status == SessionStatus.pairing);

    final issuanceSession = await repo
        .getSessionState(43)
        .firstWhere((session) => session.status == SessionStatus.requestIssuancePermission);
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

    await repo.getSessionState(43).firstWhere((session) => session.status == SessionStatus.success);

    disclosureSession = await repo.getSessionState(42).firstWhere((session) => session.satisfiable);
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

    await repo.getSessionState(42).firstWhere((session) => session.status == SessionStatus.success);
  });

  // test('issuance-in-disclosure-using-specific-attributes', () async {
}

import 'package:irmamobile/src/data/irma_mock_bridge.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/attribute_value.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';

Future<void> issueCredential(
  IrmaRepository repo,
  IrmaMockBridge mockBridge,
  int sessionID,
  List<Map<String, TextValue>> credentials, {
  Duration validity = const Duration(days: 365),
  bool revoked = false,
}) async {
  mockBridge.mockIssuanceSession(
    sessionID,
    credentials,
    validity: validity,
    revoked: revoked,
  );

  repo.dispatch(
    NewSessionEvent(sessionID: sessionID, request: SessionPointer(irmaqr: 'issuing', u: '')),
    isBridgedEvent: true,
  );
  await repo
      .getSessionState(sessionID)
      .firstWhere((session) => session.status == SessionStatus.requestIssuancePermission);

  repo.dispatch(
    RespondPermissionEvent(sessionID: sessionID, proceed: true, disclosureChoices: [[]]),
    isBridgedEvent: true,
  );
  await repo.getSessionState(sessionID).firstWhere((session) => session.status == SessionStatus.success);
}

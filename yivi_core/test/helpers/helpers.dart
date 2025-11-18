import "package:yivi_core/src/data/irma_mock_bridge.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/attribute_value.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/models/session_events.dart";
import "package:yivi_core/src/models/session_state.dart";

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

  repo.bridgedDispatch(
    NewSessionEvent(
      sessionID: sessionID,
      request: SessionPointer(irmaqr: "issuing", u: ""),
    ),
  );
  await repo
      .getSessionState(sessionID)
      .firstWhere(
        (session) => session.status == SessionStatus.requestIssuancePermission,
      );

  repo.bridgedDispatch(
    RespondPermissionEvent(
      sessionID: sessionID,
      proceed: true,
      disclosureChoices: [[]],
    ),
  );
  await repo
      .getSessionState(sessionID)
      .firstWhere((session) => session.status == SessionStatus.success);
}

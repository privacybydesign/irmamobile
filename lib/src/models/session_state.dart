import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/session.dart';

class SessionState {
  final int sessionID;
  final bool continueOnSecondDevice;
  final SessionStatus status;
  final RequestorInfo serverName;
  final ConDisCon<Attribute> disclosuresCandidates;
  final String clientReturnURL;
  final bool isSignatureSession;
  final String signedMessage;
  final List<Credential> issuedCredentials;
  final List<int> disclosureIndices;
  final ConCon<AttributeIdentifier> disclosureChoices;
  final bool satisfiable;
  final bool canBeFinished;
  final SessionError error;
  final String inAppCredential;
  final String sessionType;
  final String pairingCode;

  SessionState({
    this.sessionID,
    this.continueOnSecondDevice,
    this.status = SessionStatus.uninitialized,
    this.serverName,
    this.disclosuresCandidates,
    this.clientReturnURL,
    this.isSignatureSession,
    this.signedMessage,
    this.issuedCredentials,
    this.disclosureIndices,
    this.disclosureChoices,
    this.satisfiable,
    this.canBeFinished,
    this.error,
    this.inAppCredential,
    this.sessionType,
    this.pairingCode,
  });

  bool get canDisclose =>
      disclosuresCandidates == null ||
      disclosuresCandidates
          .asMap()
          .map((i, discon) => MapEntry(i, discon[disclosureIndices[i]]))
          .values
          .every((con) => con.every((attr) => attr.choosable));

  // We cannot fully rely on the sessionType value to determine whether it is issuance, because a
  // 'redirect' session can also be issuance. Therefore we overrule the sessionType when
  // issuedCredentials is set. IrmaGo enforces that an error is triggered in case of a problematic
  // mismatch between both values, so we can safely do this.
  bool get isIssuanceSession => issuedCredentials?.isNotEmpty ?? sessionType == 'issuing';

  bool get isReturnPhoneNumber => clientReturnURL?.startsWith("tel:") ?? false;
  bool get didIssueInappCredential =>
      issuedCredentials?.any((element) => element.info.fullId == inAppCredential) ?? false;

  bool get isFinished => [
        SessionStatus.success,
        SessionStatus.canceled,
        SessionStatus.error,
      ].contains(status);

  SessionState copyWith({
    bool continueOnSecondDevice,
    SessionStatus status,
    RequestorInfo serverName,
    ConDisCon<Attribute> disclosuresCandidates,
    String clientReturnURL,
    bool isSignatureSession,
    String signedMessage,
    List<Credential> issuedCredentials,
    List<int> disclosureIndices,
    ConCon<AttributeIdentifier> disclosureChoices,
    bool satisfiable,
    bool canBeFinished,
    SessionError error,
    String inAppCredential,
    String sessionType,
    String pairingCode,
  }) {
    return SessionState(
      sessionID: sessionID,
      continueOnSecondDevice: continueOnSecondDevice ?? this.continueOnSecondDevice,
      status: status ?? this.status,
      serverName: serverName ?? this.serverName,
      disclosuresCandidates: disclosuresCandidates ?? this.disclosuresCandidates,
      clientReturnURL: clientReturnURL ?? this.clientReturnURL,
      isSignatureSession: isSignatureSession ?? this.isSignatureSession,
      signedMessage: signedMessage ?? this.signedMessage,
      issuedCredentials: issuedCredentials ?? this.issuedCredentials,
      disclosureIndices: disclosureIndices ?? this.disclosureIndices,
      disclosureChoices: disclosureChoices ?? this.disclosureChoices,
      satisfiable: satisfiable ?? this.satisfiable,
      canBeFinished: canBeFinished ?? this.canBeFinished,
      error: error ?? this.error,
      inAppCredential: inAppCredential ?? this.inAppCredential,
      sessionType: sessionType ?? this.sessionType,
      pairingCode: pairingCode ?? this.pairingCode,
    );
  }
}

enum SessionStatus {
  uninitialized,
  initialized,
  communicating,
  pairing,
  requestDisclosurePermission,
  requestIssuancePermission,
  requestPin,
  success,
  canceled,
  error,
}

extension SessionStatusParser on String {
  SessionStatus toSessionStatus() => SessionStatus.values.firstWhere(
        (v) => v.toString() == 'SessionStatus.$this',
        orElse: () => null,
      );
}

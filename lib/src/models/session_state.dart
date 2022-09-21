import 'package:collection/collection.dart';

import '../util/con_dis_con.dart';
import 'attribute.dart';
import 'credentials.dart';
import 'return_url.dart';
import 'session.dart';

class SessionState {
  final int sessionID;
  final bool continueOnSecondDevice;
  final SessionStatus status;
  final RequestorInfo serverName;
  final ConDisCon<DisclosureCandidate>? disclosuresCandidates;
  final ReturnURL? clientReturnURL;
  final bool? isSignatureSession;
  final String? signedMessage;
  final List<Credential>? issuedCredentials;
  final ConCon<AttributeIdentifier>? disclosureChoices;
  final bool? satisfiable;
  final bool? canBeFinished;
  final SessionError? error;
  final String inAppCredential;
  final String sessionType;
  final String? pairingCode;

  SessionState({
    required this.sessionID,
    required this.continueOnSecondDevice,
    required this.status,
    required this.serverName,
    required this.inAppCredential,
    required this.sessionType,
    this.disclosuresCandidates,
    this.clientReturnURL,
    this.isSignatureSession,
    this.signedMessage,
    this.issuedCredentials,
    this.disclosureChoices,
    this.satisfiable,
    this.canBeFinished,
    this.error,
    this.pairingCode,
  });

  // We cannot fully rely on the sessionType value to determine whether it is issuance, because a
  // 'redirect' session can also be issuance. Therefore we overrule the sessionType when
  // issuedCredentials is set. IrmaGo enforces that an error is triggered in case of a problematic
  // mismatch between both values, so we can safely do this.
  bool get isIssuanceSession => issuedCredentials?.isNotEmpty ?? sessionType == 'issuing';

  bool get didIssueInappCredential =>
      issuedCredentials?.any((element) => element.info.fullId == inAppCredential) ?? false;

  bool get isFinished => [
        SessionStatus.success,
        SessionStatus.canceled,
        SessionStatus.error,
      ].contains(status);

  SessionState copyWith({
    SessionStatus? status,
    RequestorInfo? serverName,
    ConDisCon<DisclosureCandidate>? disclosuresCandidates,
    ReturnURL? clientReturnURL,
    bool? isSignatureSession,
    String? signedMessage,
    List<Credential>? issuedCredentials,
    ConCon<AttributeIdentifier>? disclosureChoices,
    bool? satisfiable,
    bool? canBeFinished,
    SessionError? error,
    String? pairingCode,
  }) {
    return SessionState(
      sessionID: sessionID,
      continueOnSecondDevice: continueOnSecondDevice,
      status: status ?? this.status,
      serverName: serverName ?? this.serverName,
      disclosuresCandidates: disclosuresCandidates ?? this.disclosuresCandidates,
      clientReturnURL: clientReturnURL ?? this.clientReturnURL,
      isSignatureSession: isSignatureSession ?? this.isSignatureSession,
      signedMessage: signedMessage ?? this.signedMessage,
      issuedCredentials: issuedCredentials ?? this.issuedCredentials,
      disclosureChoices: disclosureChoices ?? this.disclosureChoices,
      satisfiable: satisfiable ?? this.satisfiable,
      canBeFinished: canBeFinished ?? this.canBeFinished,
      error: error ?? this.error,
      inAppCredential: inAppCredential,
      sessionType: sessionType,
      pairingCode: pairingCode ?? this.pairingCode,
    );
  }
}

enum SessionStatus {
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
  SessionStatus? toSessionStatus() => SessionStatus.values.firstWhereOrNull(
        (v) => v.toString() == 'SessionStatus.$this',
      );
}

import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/translated_value.dart';

class SessionState {
  final int sessionID;
  final bool continueOnSecondDevice;
  final SessionStatus status;
  final TranslatedValue serverName;
  final ConDisCon<Attribute> disclosuresCandidates;
  final String clientReturnURL;
  final bool isSignatureSession;
  final String signedMessage;
  final List<int> disclosureIndices;
  final ConCon<AttributeIdentifier> disclosureChoices;
  final bool satisfiable;

  SessionState({
    this.sessionID,
    this.continueOnSecondDevice,
    this.status = SessionStatus.uninitialized,
    this.serverName,
    this.disclosuresCandidates,
    this.clientReturnURL,
    this.isSignatureSession,
    this.signedMessage,
    this.disclosureIndices,
    this.disclosureChoices,
    this.satisfiable,
  });

  bool get canDisclose => disclosuresCandidates
      .asMap()
      .map((i, discon) => MapEntry(i, discon[disclosureIndices[i]]))
      .values
      .every((con) => con.every((attr) => attr.choosable));

  SessionState copyWith({
    bool continueOnSecondDevice,
    SessionStatus status,
    TranslatedValue serverName,
    ConDisCon<Attribute> disclosuresCandidates,
    String clientReturnURL,
    bool isSignatureSession,
    String signedMessage,
    List<int> disclosureIndices,
    ConCon<AttributeIdentifier> disclosureChoices,
    bool satisfiable,
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
      disclosureIndices: disclosureIndices ?? this.disclosureIndices,
      disclosureChoices: disclosureChoices ?? this.disclosureChoices,
      satisfiable: satisfiable ?? this.satisfiable,
    );
  }
}

enum SessionStatus {
  uninitialized,
  initialized,
  communicating,
  connected,
  requestPermission,
  success,
}

extension SessionStatusParser on String {
  SessionStatus toSessionStatus() => SessionStatus.values.firstWhere(
        (v) => v.toString() == 'SessionStatus.$this',
        orElse: () => null,
      );
}

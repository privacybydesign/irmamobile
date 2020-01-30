import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/translated_value.dart';

class SessionState {
  final int sessionID;
  final bool continueOnSecondDevice;
  final SessionStatus status;
  final TranslatedValue serverName;
  final ConDisCon<CredentialAttribute> disclosuresCandidates;
  final String clientReturnURL;

  SessionState({
    this.sessionID,
    this.continueOnSecondDevice,
    this.status = SessionStatus.uninitialized,
    this.serverName,
    this.disclosuresCandidates,
    this.clientReturnURL,
  });

  SessionState copyWith({
    bool continueOnSecondDevice,
    SessionStatus status,
    TranslatedValue serverName,
    ConDisCon<CredentialAttribute> disclosuresCandidates,
    String clientReturnURL,
  }) {
    return SessionState(
      sessionID: sessionID,
      continueOnSecondDevice: continueOnSecondDevice ?? this.continueOnSecondDevice,
      status: status ?? this.status,
      serverName: serverName ?? this.serverName,
      disclosuresCandidates: disclosuresCandidates ?? this.disclosuresCandidates,
      clientReturnURL: clientReturnURL ?? this.clientReturnURL,
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

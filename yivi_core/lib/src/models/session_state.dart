import "package:collection/collection.dart";

import "../util/con_dis_con.dart";
import "attribute.dart";
import "credentials.dart";
import "return_url.dart";
import "session.dart";

class SessionState {
  final int sessionID;

  bool get isIssuanceSession => false;
  bool get isFinished => false;

  SessionState({required this.sessionID});
}

class AuthorizationCodeRequestParametersState {
  AuthorizationCodeRequestParametersState({
    required this.issuerDiscoveryUrl,
    required this.resource,
    required this.scopes,
    this.issuerState,
  });
  final String issuerDiscoveryUrl;
  final String? issuerState;
  final String resource;
  final List<String> scopes;
}

class PreAuthorizationCodeTransactionCodeParametersState {
  PreAuthorizationCodeTransactionCodeParametersState({
    required this.inputMode,
    this.length,
    this.description,
  });
  final String inputMode;
  final int? length;
  final String? description;
}

class OpenID4VciSessionState extends SessionState {
  OpenID4VciSessionState({
    required super.sessionID,
    required this.continueOnSecondDevice,
    this.error,
    this.requestorInfo,
    this.credentialInfoList,
    this.grantType,
    this.authorizationCodeRequestParameters,
    this.transactionCodeParameters,
    this.dismissed = false,
    this.status = .initialized,
  });

  final bool continueOnSecondDevice;
  final SessionError? error;
  final RequestorInfo? requestorInfo;
  final List<CredentialTypeInfo>? credentialInfoList;
  final String? grantType;
  final AuthorizationCodeRequestParametersState?
  authorizationCodeRequestParameters;
  final PreAuthorizationCodeTransactionCodeParametersState?
  transactionCodeParameters;
  final bool dismissed;
  final SessionStatus status;

  OpenID4VciSessionState copyWith({
    SessionError? error,
    RequestorInfo? requestorInfo,
    List<CredentialTypeInfo>? credentialInfoList,
    bool? continueOnSecondDevice,
    String? grantType,
    AuthorizationCodeRequestParametersState? authorizationCodeRequestParameters,
    PreAuthorizationCodeTransactionCodeParametersState?
    transactionCodeParameters,
    bool? dismissed,
    SessionStatus? status,
  }) {
    return OpenID4VciSessionState(
      sessionID: sessionID,
      continueOnSecondDevice:
          continueOnSecondDevice ?? this.continueOnSecondDevice,
      error: error ?? this.error,
      requestorInfo: requestorInfo ?? this.requestorInfo,
      credentialInfoList: credentialInfoList ?? this.credentialInfoList,
      grantType: grantType ?? this.grantType,
      authorizationCodeRequestParameters:
          authorizationCodeRequestParameters ??
          this.authorizationCodeRequestParameters,
      transactionCodeParameters:
          transactionCodeParameters ?? this.transactionCodeParameters,
      dismissed: dismissed ?? this.dismissed,
      status: status ?? this.status,
    );
  }

  @override
  bool get isIssuanceSession => true;
}

class IrmaSessionState extends SessionState {
  final bool continueOnSecondDevice;
  final SessionStatus status;
  final RequestorInfo serverName;
  final ConDisCon<DisclosureCandidate>? disclosuresCandidates;
  final ReturnURL? clientReturnURL;
  final bool? isSignatureSession;
  final String? signedMessage;
  final List<MultiFormatCredential>? issuedCredentials;
  final ConCon<AttributeIdentifier>? disclosureChoices;
  final bool? satisfiable;
  final bool? canBeFinished;
  final SessionError? error;
  final Set<String> previouslyLaunchedCredentials;
  final String sessionType;
  final String? pairingCode;
  final bool dismissed;

  IrmaSessionState({
    required super.sessionID,
    required this.continueOnSecondDevice,
    required this.status,
    required this.serverName,
    required this.previouslyLaunchedCredentials,
    required this.sessionType,
    this.dismissed = false,
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
  @override
  bool get isIssuanceSession =>
      issuedCredentials?.isNotEmpty ?? sessionType == "issuing";

  // Indicates that this session contains a credential that
  // the user previously tried to obtain via the credential store
  // or by reobtain a credential from the data tab.
  bool get didIssuePreviouslyLaunchedCredential =>
      issuedCredentials?.any(
        (cred) =>
            previouslyLaunchedCredentials.contains(cred.credentialType.fullId),
      ) ??
      false;

  @override
  bool get isFinished => [
    SessionStatus.success,
    SessionStatus.canceled,
    SessionStatus.error,
  ].contains(status);

  IrmaSessionState copyWith({
    SessionStatus? status,
    RequestorInfo? serverName,
    ConDisCon<DisclosureCandidate>? disclosuresCandidates,
    ReturnURL? clientReturnURL,
    bool? isSignatureSession,
    String? signedMessage,
    List<MultiFormatCredential>? issuedCredentials,
    ConCon<AttributeIdentifier>? disclosureChoices,
    bool? satisfiable,
    bool? canBeFinished,
    SessionError? error,
    String? pairingCode,
    bool? dismissed,
  }) {
    return IrmaSessionState(
      sessionID: sessionID,
      continueOnSecondDevice: continueOnSecondDevice,
      status: status ?? this.status,
      serverName: serverName ?? this.serverName,
      disclosuresCandidates:
          disclosuresCandidates ?? this.disclosuresCandidates,
      clientReturnURL: clientReturnURL ?? this.clientReturnURL,
      isSignatureSession: isSignatureSession ?? this.isSignatureSession,
      signedMessage: signedMessage ?? this.signedMessage,
      issuedCredentials: issuedCredentials ?? this.issuedCredentials,
      disclosureChoices: disclosureChoices ?? this.disclosureChoices,
      satisfiable: satisfiable ?? this.satisfiable,
      canBeFinished: canBeFinished ?? this.canBeFinished,
      error: error ?? this.error,
      previouslyLaunchedCredentials: previouslyLaunchedCredentials,
      sessionType: sessionType,
      pairingCode: pairingCode ?? this.pairingCode,
      dismissed: dismissed ?? this.dismissed,
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
    (v) => v.toString() == "SessionStatus.$this",
  );
}

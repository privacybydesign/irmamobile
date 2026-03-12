import "package:json_annotation/json_annotation.dart";

import "../event.dart";
import "../log_entry.dart";
import "../session.dart";
import "../translated_value.dart";
import "credential_store.dart";
import "schemaless_events.dart";

part "session_state.g.dart";

@JsonSerializable(createToJson: false, fieldRename: .snake)
class SessionStateEvent extends Event {
  final SessionState sessionState;

  SessionStateEvent({required this.sessionState});

  factory SessionStateEvent.fromJson(Map<String, dynamic> json) =>
      _$SessionStateEventFromJson(json);
}

@JsonEnum(alwaysCreate: true, fieldRename: .snake)
enum SessionType { disclosure, issuance, signature }

@JsonEnum(alwaysCreate: true, fieldRename: .snake)
enum SessionStatus {
  requestPermission,
  showPairingCode,
  success,
  error,
  dismissed,
  requestPin,
  requestAuthorizationCode,
}

@JsonSerializable(createToJson: false, fieldRename: .snake)
class SessionState {
  final int id;
  final String protocol;
  final SessionType type;
  final SessionStatus status;
  final TrustedParty requestor;
  final String? pairingCode;
  final List<Credential>? offeredCredentials;
  final DisclosurePlan? disclosurePlan;
  final String? messageToSign;
  final SessionError? error;
  final String? clientReturnUrl;
  final bool continueOnSecondDevice;
  final int remainingPinAttempts;
  final int pinBlockedTimeSeconds;

  SessionState({
    required this.id,
    required this.protocol,
    required this.type,
    required this.status,
    required this.requestor,
    this.pairingCode,
    this.offeredCredentials,
    this.disclosurePlan,
    this.messageToSign,
    this.error,
    this.clientReturnUrl,
    this.continueOnSecondDevice = false,
    this.remainingPinAttempts = 0,
    this.pinBlockedTimeSeconds = 0,
  });

  factory SessionState.fromJson(Map<String, dynamic> json) =>
      _$SessionStateFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: .snake)
class DisclosurePlan {
  final IssueDuringDislosure? issueDuringDislosure;
  final List<DisclosurePickOne>? disclosureChoicesOverview;

  DisclosurePlan({this.issueDuringDislosure, this.disclosureChoicesOverview});

  factory DisclosurePlan.fromJson(Map<String, dynamic> json) =>
      _$DisclosurePlanFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: .snake)
class IssueDuringDislosure {
  final List<IssuanceStep> steps;
  final Map<String, dynamic>? issuedCredentialIds;

  IssueDuringDislosure({required this.steps, this.issuedCredentialIds});

  factory IssueDuringDislosure.fromJson(Map<String, dynamic> json) =>
      _$IssueDuringDislosureFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: .snake)
class IssuanceStep {
  final List<CredentialDescriptor> options;

  IssuanceStep({required this.options});

  factory IssuanceStep.fromJson(Map<String, dynamic> json) =>
      _$IssuanceStepFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: .snake)
class DisclosurePickOne {
  final bool optional;
  final List<SelectableCredentialInstance>? ownedOptions;
  final List<CredentialDescriptor>? obtainableOptions;

  DisclosurePickOne({
    required this.optional,
    this.ownedOptions,
    this.obtainableOptions,
  });

  factory DisclosurePickOne.fromJson(Map<String, dynamic> json) =>
      _$DisclosurePickOneFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: .snake)
class SelectableCredentialInstance {
  final String credentialId;
  final String hash;
  final String imagePath;
  final TranslatedValue name;
  final TrustedParty issuer;
  final CredentialFormat format;
  final int? batchInstanceCountRemaining;
  final List<Attribute> attributes;
  final int issuanceDate;
  final int expiryDate;
  final bool revoked;
  final bool revocationSupported;
  final TranslatedValue? issueUrl;

  SelectableCredentialInstance({
    required this.credentialId,
    required this.hash,
    required this.imagePath,
    required this.name,
    required this.issuer,
    required this.format,
    required this.attributes,
    required this.issuanceDate,
    required this.expiryDate,
    required this.revoked,
    required this.revocationSupported,
    this.batchInstanceCountRemaining,
    this.issueUrl,
  });

  factory SelectableCredentialInstance.fromJson(Map<String, dynamic> json) =>
      _$SelectableCredentialInstanceFromJson(json);
}

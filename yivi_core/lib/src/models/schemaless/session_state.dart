import "package:json_annotation/json_annotation.dart";

import "../event.dart";
import "../log_entry.dart";
import "../translated_value.dart";
import "credential_store.dart";
import "schemaless_events.dart";

part "session_state.g.dart";

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class SessionStateEvent extends Event {
  final SessionState sessionState;

  SessionStateEvent({required this.sessionState});

  factory SessionStateEvent.fromJson(Map<String, dynamic> json) =>
      _$SessionStateEventFromJson(json);
}

@JsonEnum(alwaysCreate: true)
enum SessionType {
  @JsonValue("disclosure")
  disclosure,

  @JsonValue("issuance")
  issuance,

  @JsonValue("signature")
  signature,
}

@JsonEnum(alwaysCreate: true)
enum SessionStatus {
  @JsonValue("request_permission")
  requestPermission,

  @JsonValue("show_pairing_code")
  showPairingCode,

  @JsonValue("success")
  success,

  @JsonValue("error")
  error,

  @JsonValue("dismissed")
  dismissed,

  @JsonValue("request_pin")
  requestPin,
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
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

  final String? error;

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

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class DisclosurePlan {
  final IssueDuringDislosure? issueDuringDislosure;

  final List<DisclosurePickOne> disclosureChoicesOverview;

  DisclosurePlan({
    this.issueDuringDislosure,
    required this.disclosureChoicesOverview,
  });

  factory DisclosurePlan.fromJson(Map<String, dynamic> json) =>
      _$DisclosurePlanFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class IssueDuringDislosure {
  final List<IssuanceStep> steps;

  final Map<String, dynamic>? issuedCredentialIds;

  IssueDuringDislosure({required this.steps, this.issuedCredentialIds});

  factory IssueDuringDislosure.fromJson(Map<String, dynamic> json) =>
      _$IssueDuringDislosureFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class IssuanceStep {
  final List<CredentialDescriptor> options;

  IssuanceStep({required this.options});

  factory IssuanceStep.fromJson(Map<String, dynamic> json) =>
      _$IssuanceStepFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
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

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
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
    this.batchInstanceCountRemaining,
    required this.attributes,
    required this.issuanceDate,
    required this.expiryDate,
    required this.revoked,
    required this.revocationSupported,
    this.issueUrl,
  });

  factory SelectableCredentialInstance.fromJson(Map<String, dynamic> json) =>
      _$SelectableCredentialInstanceFromJson(json);
}

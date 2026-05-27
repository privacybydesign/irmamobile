import "package:json_annotation/json_annotation.dart";

import "../event.dart";
import "../log_entry.dart";
import "../return_url.dart";
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
  requestPreAuthorizedCode,
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
  final List<CredentialDescriptor>? offeredCredentialTypes;
  final DisclosurePlan? disclosurePlan;
  final String? messageToSign;
  final SessionError? error;
  final String? clientReturnUrl;
  final bool continueOnSecondDevice;
  final int? remainingPinAttempts;
  final int? pinBlockedTimeSeconds;
  @JsonKey(name: "openid4vci_state")
  final String? openID4VCIState;
  final String? authorizationRequestUrl;
  final PreAuthorizationCodeTransactionCodeParameters?
  transactionCodeParameters;
  final int? remainingTxCodeAttempts;

  SessionState({
    required this.id,
    required this.protocol,
    required this.type,
    required this.status,
    required this.requestor,
    this.pairingCode,
    this.offeredCredentials,
    this.offeredCredentialTypes,
    this.disclosurePlan,
    this.messageToSign,
    this.error,
    this.clientReturnUrl,
    this.continueOnSecondDevice = false,
    this.remainingPinAttempts,
    this.pinBlockedTimeSeconds,
    this.openID4VCIState,
    this.authorizationRequestUrl,
    this.transactionCodeParameters,
    this.remainingTxCodeAttempts,
  });

  factory SessionState.fromJson(Map<String, dynamic> json) =>
      _$SessionStateFromJson(json);

  ReturnURL? get parsedClientReturnUrl => ReturnURL.parse(clientReturnUrl);
}

@JsonSerializable(createToJson: false, fieldRename: .snake)
class DisclosurePlan {
  final IssueDuringDisclosure? issueDuringDisclosure;
  final List<DisclosurePickOne>? disclosureChoicesOverview;

  DisclosurePlan({this.issueDuringDisclosure, this.disclosureChoicesOverview});

  factory DisclosurePlan.fromJson(Map<String, dynamic> json) =>
      _$DisclosurePlanFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: .snake)
class IssueDuringDisclosure {
  final List<IssuanceStep> steps;
  final Map<String, dynamic>? issuedCredentialIds;
  final Credential? wrongCredentialIssued;

  IssueDuringDisclosure({
    required this.steps,
    this.issuedCredentialIds,
    this.wrongCredentialIssued,
  });

  factory IssueDuringDisclosure.fromJson(Map<String, dynamic> json) =>
      _$IssueDuringDisclosureFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: .snake)
class IssuanceStep {
  final List<IssuanceBundle> options;

  // A step with no bundles cannot be rendered or progressed. We reject it at
  // the boundary so a malformed backend response surfaces here, instead of as
  // a RangeError deep in the UI when `options[selectedIndex]` is indexed.
  IssuanceStep({required this.options}) {
    if (options.isEmpty) {
      throw ArgumentError.value(
        options,
        "options",
        "IssuanceStep.options must be non-empty",
      );
    }
  }

  factory IssuanceStep.fromJson(Map<String, dynamic> json) =>
      _$IssuanceStepFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: .snake)
class IssuanceBundle {
  final List<CredentialDescriptor> credentials;

  IssuanceBundle({required this.credentials});

  factory IssuanceBundle.fromJson(Map<String, dynamic> json) =>
      _$IssuanceBundleFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: .snake)
class DisclosurePickOne {
  final bool optional;
  final List<DisclosureBundle>? ownedOptions;
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
class DisclosureBundle {
  final List<SelectableCredentialInstance> credentials;

  DisclosureBundle({required this.credentials});

  factory DisclosureBundle.fromJson(Map<String, dynamic> json) =>
      _$DisclosureBundleFromJson(json);

  Set<String> get credentialHashes => credentials.map((c) => c.hash).toSet();
}

@JsonSerializable(createToJson: false, fieldRename: .snake)
class SelectableCredentialInstance {
  final String credentialId;
  final String hash;
  final String? imagePath;
  final LogoImage? image;
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
    required this.name,
    required this.issuer,
    required this.format,
    required this.attributes,
    required this.issuanceDate,
    required this.expiryDate,
    required this.revoked,
    required this.revocationSupported,
    this.imagePath,
    this.image,
    this.batchInstanceCountRemaining,
    this.issueUrl,
  });

  factory SelectableCredentialInstance.fromJson(Map<String, dynamic> json) =>
      _$SelectableCredentialInstanceFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: .snake)
class PreAuthorizationCodeTransactionCodeParameters {
  PreAuthorizationCodeTransactionCodeParameters({
    required this.inputMode,
    this.length,
    this.description,
  });
  final String inputMode;
  final int? length;
  final String? description;

  factory PreAuthorizationCodeTransactionCodeParameters.fromJson(
    Map<String, dynamic> json,
  ) => _$PreAuthorizationCodeTransactionCodeParametersFromJson(json);
}

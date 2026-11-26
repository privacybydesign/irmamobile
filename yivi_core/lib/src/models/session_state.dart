import "package:json_annotation/json_annotation.dart";

import "credential.dart";
import "credential_store.dart";
import "event.dart";
import "log_entry.dart";
import "protocol.dart";
import "return_url.dart";
import "session.dart";

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
  requestAuthorizationCode;

  /// Whether the session has ended: it worked, failed or was dismissed.
  bool get isTerminal => this == success || this == error || this == dismissed;
}

@JsonSerializable(createToJson: false, fieldRename: .snake)
class SessionState {
  final int id;

  /// The protocol as irmago names it; see [knownProtocol].
  final String protocol;

  /// [protocol], or null for one this app does not know (the technical
  /// details then show irmago's name for it).
  Protocol? get knownProtocol => switch (protocol) {
    "irma" => Protocol.irma,
    "openid4vp" => Protocol.openid4vp,
    "openid4vci" => Protocol.openid4vci,
    _ => null,
  };

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

  /// How an OpenID4VP response travels to the verifier (e.g.
  /// `direct_post.jwt`), for the technical details. Absent for IRMA, or
  /// when irmago does not send it.
  final String? responseMode;

  /// With [SessionStatus.success]: the requestor chained a follow-up request.
  /// This session is done; the follow-up starts on
  /// `SessionUserInteractionEvent.continueNextSession`, and is dropped when
  /// the session is dismissed.
  final bool nextSessionPending;

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
    this.nextSessionPending = false,
    this.remainingTxCodeAttempts,
    this.responseMode,
  });

  factory SessionState.fromJson(Map<String, dynamic> json) =>
      _$SessionStateFromJson(json);

  ReturnURL? get parsedClientReturnUrl => ReturnURL.parse(clientReturnUrl);
}

/// A disclosure (or signature) request as irmago describes it: choices →
/// options → slots → candidates.
@JsonSerializable(createToJson: false, fieldRename: .snake)
class DisclosurePlan {
  /// One per IRMA discon, DCQL credential set, or DCQL query without sets,
  /// in request order.
  @JsonKey(defaultValue: <DisclosureChoice>[])
  final List<DisclosureChoice> choices;

  /// The types issued since the request was first shown.
  final Map<String, dynamic>? issuedCredentialIds;

  /// A card added for the request that does not satisfy it, with only the
  /// attributes that do not match.
  final Credential? wrongCredentialIssued;

  DisclosurePlan({
    required this.choices,
    this.issuedCredentialIds,
    this.wrongCredentialIssued,
  });

  factory DisclosurePlan.fromJson(Map<String, dynamic> json) =>
      _$DisclosurePlanFromJson(json);
}

/// One thing the requestor wants answered. Exactly one option is shared, or
/// none when it is [optional].
@JsonSerializable(createToJson: false, fieldRename: .snake)
class DisclosureChoice {
  final bool optional;
  @JsonKey(defaultValue: <DisclosureOption>[])
  final List<DisclosureOption> options;

  DisclosureChoice({required this.optional, required this.options});

  factory DisclosureChoice.fromJson(Map<String, dynamic> json) =>
      _$DisclosureChoiceFromJson(json);
}

/// One way to answer a choice: all its slots are shared together.
@JsonSerializable(createToJson: false, fieldRename: .snake)
class DisclosureOption {
  @JsonKey(defaultValue: <DisclosureSlot>[])
  final List<DisclosureSlot> slots;

  DisclosureOption({required this.slots});

  factory DisclosureOption.fromJson(Map<String, dynamic> json) =>
      _$DisclosureOptionFromJson(json);
}

/// One card an option needs: a DCQL query, or one credential type of an IRMA
/// con.
@JsonSerializable(createToJson: false, fieldRename: .snake)
class DisclosureSlot {
  /// DCQL: the query id; one query in two sets is one slot with one
  /// selection. IRMA: "{discon index}:{credential type id}".
  final String id;

  /// Takes one or more cards (DCQL `multiple`).
  final bool multiple;

  /// The cards in the app that fit, best first, each with only what it would
  /// share. Unusable ones are included, with [SelectableCredentialInstance.usable]
  /// false.
  @JsonKey(defaultValue: <SelectableCredentialInstance>[])
  final List<SelectableCredentialInstance> candidates;

  /// What can be added for this slot. A descriptor without an issue URL says
  /// what is asked when it cannot be added.
  @JsonKey(defaultValue: <CredentialDescriptor>[])
  final List<CredentialDescriptor> obtainable;

  DisclosureSlot({
    required this.id,
    this.multiple = false,
    required this.candidates,
    required this.obtainable,
  });

  factory DisclosureSlot.fromJson(Map<String, dynamic> json) =>
      _$DisclosureSlotFromJson(json);
}

/// Why a candidate cannot be shared for this request.
@JsonEnum(fieldRename: .snake)
enum UnusableReason { revoked, expired, usedUp, notRevocable }

@JsonSerializable(createToJson: false, fieldRename: .snake)
class SelectableCredentialInstance {
  final String credentialId;
  final String hash;
  final String? imagePath;
  final LogoImage? image;
  final String name;
  final TrustedParty issuer;
  final CredentialFormat format;
  final int? batchInstanceCountRemaining;
  final List<Attribute> attributes;
  final int? issuanceDate;
  final int? expiryDate;
  final bool revoked;
  final bool revocationSupported;
  final String? issueUrl;

  /// The scheme allows only one card of this type in the app: a new one
  /// replaces the old one. False when irmago does not send it, and for types
  /// without a scheme entry.
  final bool isSingleton;

  /// irmago's verdict for this request: the card can be shared. Never derived
  /// in the app from [expiryDate] or [revoked].
  final bool usable;

  /// Why the card cannot be shared; null when [usable].
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final UnusableReason? unusableReason;

  SelectableCredentialInstance({
    required this.credentialId,
    required this.hash,
    required this.name,
    required this.issuer,
    required this.format,
    required this.attributes,
    required this.revoked,
    required this.revocationSupported,
    this.issuanceDate,
    this.expiryDate,
    this.imagePath,
    this.image,
    this.batchInstanceCountRemaining,
    this.issueUrl,
    this.isSingleton = false,
    this.usable = false,
    this.unusableReason,
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

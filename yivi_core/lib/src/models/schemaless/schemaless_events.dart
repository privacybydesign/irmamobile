import "package:json_annotation/json_annotation.dart";

import "../event.dart";
import "../log_entry.dart";

part "schemaless_events.g.dart";

@JsonSerializable(createToJson: false, fieldRename: .snake)
class SchemalessCredentialsEvent extends Event {
  final List<Credential> credentials;

  /// Credentials the wallet has stored but cannot render (e.g. an IRMA
  /// credential whose scheme is gone). Kept separate from [credentials] so one
  /// bad credential never blanks the overview; each carries the hash(es) needed
  /// to delete it.
  final List<ProblematicCredential> problematic;

  SchemalessCredentialsEvent({
    required this.credentials,
    this.problematic = const [],
  });

  factory SchemalessCredentialsEvent.fromJson(Map<String, dynamic> json) =>
      _$SchemalessCredentialsEventFromJson(json);
}

/// A credential the wallet stored but cannot load into a full [Credential].
/// Mirrors irmago's `clientmodels.ProblematicCredential`.
@JsonSerializable(fieldRename: .snake)
class ProblematicCredential {
  /// Maps each format this instance exists in to its storage hash, so it can be
  /// deleted with a [DeleteCredentialEvent] without resolving its metadata.
  final Map<CredentialFormat, String> credentialInstanceIds;

  /// Why the credential could not be loaded (for display/diagnostics).
  final String reason;

  /// Best-effort credential id (IRMA type id or EUDI vct) if recoverable.
  final String? credentialId;

  ProblematicCredential({
    required this.credentialInstanceIds,
    required this.reason,
    this.credentialId,
  });

  factory ProblematicCredential.fromJson(Map<String, dynamic> json) =>
      _$ProblematicCredentialFromJson(json);

  Map<String, dynamic> toJson() => _$ProblematicCredentialToJson(this);
}

/// The credentials the wallet holds, as one snapshot: the ones it can render and
/// the ones it stored but cannot load ([ProblematicCredential]). Both come from
/// a single [SchemalessCredentialsEvent], so they always travel together.
typedef SchemalessCredentials = ({
  List<Credential> credentials,
  List<ProblematicCredential> problematic,
});

@JsonEnum(alwaysCreate: true, fieldRename: .snake)
enum AttributeType { string, boolean, integer, image, base64Image }

@JsonSerializable(fieldRename: .snake)
class AttributeValue {
  final AttributeType type;
  @JsonKey(name: "int")
  final int? intValue;
  @JsonKey(name: "bool")
  final bool? boolValue;
  final String? string;
  final String? imagePath;
  final String? base64Image;

  /// The attribute type's display hint from the scheme, e.g. "yesno" or
  /// "currency:EUR". Older irmago versions don't send it, so it may be null
  /// for values that have a hint in the scheme.
  final String? displayHint;

  AttributeValue({
    required this.type,
    this.intValue,
    this.boolValue,
    this.string,
    this.imagePath,
    this.base64Image,
    this.displayHint,
  });

  /// Whether this value has actual data set (not just a type marker).
  bool get hasConcreteValue =>
      intValue != null ||
      boolValue != null ||
      string != null ||
      imagePath != null ||
      base64Image != null;

  factory AttributeValue.fromJson(Map<String, dynamic> json) =>
      _$AttributeValueFromJson(json);

  Map<String, dynamic> toJson() => _$AttributeValueToJson(this);
}

@JsonSerializable(fieldRename: .snake)
class Attribute {
  final List<dynamic> claimPath;
  final String? displayName;
  final String? description;
  final AttributeValue? value;
  final AttributeValue? requestedValue;

  /// Whether the verifier declared it will retain this attribute after the
  /// session. Only mdoc requests can say this: set (true or false) on every
  /// mdoc attribute, null for every other format. Decoded so nothing is lost;
  /// the permission screen does not show it yet.
  final bool? intentToRetain;

  /// The `svg_id` this claim has in the SD-JWT VC type metadata: the name of
  /// the `{{placeholder}}` in the issuer's SVG card template that shows its
  /// value. Null for formats and claims without one.
  final String? svgId;

  Attribute({
    required this.claimPath,
    required this.displayName,
    this.description,
    this.value,
    this.requestedValue,
    this.intentToRetain,
    this.svgId,
  });

  /// The display name to render in the UI. Falls back to the last non-int
  /// segment of [claimPath] when the backend did not supply a display name,
  /// so the UI shows the field identifier instead of an empty label. Int
  /// segments (array indices) are skipped so positions like
  /// `["tags", 0]` fall back to "tags" rather than "0".
  String get effectiveDisplayName {
    final name = displayName;
    if (name != null && name.isNotEmpty) return name;
    if (claimPath.isEmpty) return name ?? "";
    for (var i = claimPath.length - 1; i >= 0; i--) {
      final seg = claimPath[i];
      if (seg is String) return seg;
    }
    return claimPath.join(".");
  }

  /// A string key for a claim path, so paths can be compared and used in
  /// maps. Whole numbers (array indices, which JSON may decode as doubles)
  /// get the same key whether they arrive as int or double.
  static String pathKey(List<dynamic> path) => path
      .map((e) => e is num && e == e.truncate() ? "i${e.toInt()}" : "s$e")
      .join("|");

  factory Attribute.fromJson(Map<String, dynamic> json) =>
      _$AttributeFromJson(json);

  Map<String, dynamic> toJson() => _$AttributeToJson(this);
}

@JsonSerializable(fieldRename: .snake)
class TrustedParty {
  final String id;
  final String name;
  final String? url;
  final String? imagePath;
  final LogoImage? image;
  final TrustedParty? parent;

  /// Whether Yivi vouches for the party, as irmago sent it before the trust
  /// ladder. irmago with the ladder sends [trustLevel] instead, and no
  /// `verified`.
  @JsonKey(defaultValue: false)
  final bool verified;

  /// The rung of irmago's trust ladder: "low", "medium" or "high". Absent
  /// when nothing was evaluated, or from an irmago without the ladder.
  final String? trustLevel;

  /// Where the trust comes from: "yivi_scheme", "yivi_trust_list",
  /// "eu_trusted_list" or "other". Absent when unknown.
  final String? trustSource;

  /// The display name of the list or authority that vouches, if any.
  final String? trustAnchor;

  /// What the trust rests on, for the technical details.
  final TrustEvidence? evidence;

  TrustedParty({
    required this.id,
    required this.name,
    required this.url,
    required this.parent,
    required this.verified,
    this.imagePath,
    this.image,
    this.trustLevel,
    this.trustSource,
    this.trustAnchor,
    this.evidence,
  });

  factory TrustedParty.fromJson(Map<String, dynamic> json) =>
      _$TrustedPartyFromJson(json);

  Map<String, dynamic> toJson() => _$TrustedPartyToJson(this);
}

/// What a party's trust rests on: its registration in a Yivi scheme, or the
/// certificate it presented. Shown in the technical details only.
@JsonSerializable(fieldRename: .snake)
class TrustEvidence {
  /// The identifier under which the party is registered, e.g.
  /// `pbdf-requestors.webshopnoord`.
  final String? registrationId;
  final TrustCertificate? certificate;

  TrustEvidence({this.registrationId, this.certificate});

  factory TrustEvidence.fromJson(Map<String, dynamic> json) =>
      _$TrustEvidenceFromJson(json);

  Map<String, dynamic> toJson() => _$TrustEvidenceToJson(this);
}

/// The certificate a party presented (OpenID4VP): who it names, who issued
/// it, and until when (seconds since the epoch).
@JsonSerializable(fieldRename: .snake)
class TrustCertificate {
  final String subject;
  final String issuer;
  final int? notAfter;

  TrustCertificate({
    required this.subject,
    required this.issuer,
    this.notAfter,
  });

  factory TrustCertificate.fromJson(Map<String, dynamic> json) =>
      _$TrustCertificateFromJson(json);

  Map<String, dynamic> toJson() => _$TrustCertificateToJson(this);
}

@JsonSerializable(fieldRename: .snake)
class LogoImage {
  final String base64;
  final String? mimeType;

  LogoImage({required this.base64, this.mimeType});

  factory LogoImage.fromJson(Map<String, dynamic> json) =>
      _$LogoImageFromJson(json);

  Map<String, dynamic> toJson() => _$LogoImageToJson(this);
}

/// One issuer SVG card template from SD-JWT VC type metadata
/// (`display[].rendering.svg_templates[]`), already fetched, integrity-checked
/// and sanitised by irmago.
@JsonSerializable(fieldRename: .snake)
class SvgCardTemplate {
  final String svg;

  /// `portrait` or `landscape`; null when the issuer did not say.
  final String? orientation;

  /// `light` or `dark`; null when the issuer did not say.
  final String? colorScheme;

  /// `normal` or `high`; null when the issuer did not say.
  final String? contrast;

  SvgCardTemplate({
    required this.svg,
    this.orientation,
    this.colorScheme,
    this.contrast,
  });

  factory SvgCardTemplate.fromJson(Map<String, dynamic> json) =>
      _$SvgCardTemplateFromJson(json);

  Map<String, dynamic> toJson() => _$SvgCardTemplateToJson(this);
}

/// How the issuer wants the credential to look. Every field is optional:
/// IRMA credentials only get [logoTint]; SD-JWT VC credentials get whatever
/// their type metadata and issuer metadata provide.
@JsonSerializable(fieldRename: .snake)
class CredentialDisplay {
  /// CSS colour, e.g. `#1E5B46`.
  final String? backgroundColor;

  /// CSS colour, e.g. `#FFFFFF`.
  final String? textColor;

  final LogoImage? backgroundImage;

  /// Dominant colour of the credential logo (`#RRGGBB`), worked out by
  /// irmago. Used to tint the Yivi card for credentials without colours.
  final String? logoTint;

  final List<SvgCardTemplate> svgTemplates;

  CredentialDisplay({
    this.backgroundColor,
    this.textColor,
    this.backgroundImage,
    this.logoTint,
    this.svgTemplates = const [],
  });

  factory CredentialDisplay.fromJson(Map<String, dynamic> json) =>
      _$CredentialDisplayFromJson(json);

  Map<String, dynamic> toJson() => _$CredentialDisplayToJson(this);
}

@JsonSerializable(fieldRename: .snake)
class Credential {
  final String credentialId;
  final String hash;
  final LogoImage? image;

  /// Card rendering hints; null when irmago sent none.
  final CredentialDisplay? display;
  final String name;
  final TrustedParty issuer;
  final Map<CredentialFormat, String> credentialInstanceIds;
  final Map<CredentialFormat, int?> batchInstanceCountsRemaining;
  final List<Attribute> attributes;
  final int? issuanceDate;
  final int? expiryDate;
  final bool revoked;
  final bool revocationSupported;
  final String? issueUrl;

  Credential({
    required this.credentialId,
    required this.hash,
    required this.name,
    required this.issuer,
    required this.credentialInstanceIds,
    required this.batchInstanceCountsRemaining,
    required this.attributes,
    required this.revoked,
    required this.revocationSupported,
    required this.issueUrl,
    this.image,
    this.display,
    this.issuanceDate,
    this.expiryDate,
  });

  factory Credential.fromJson(Map<String, dynamic> json) =>
      _$CredentialFromJson(json);

  Map<String, dynamic> toJson() => _$CredentialToJson(this);
}

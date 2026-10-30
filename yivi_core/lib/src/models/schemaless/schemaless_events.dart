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

  /// The type of a [base64Image], recognised by irmago from the image itself,
  /// e.g. "image/png" or "image/svg+xml". Null when irmago did not recognise
  /// it, or is too old to send it.
  final String? mimeType;

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
    this.mimeType,
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

/// Turns a claim key into a label, for a claim the issuer gave no display
/// name: camelCase and snake_case are split into words, the first word is
/// capitalised and the rest lowercased, and all-caps words such as "ECTS" or
/// "BRIN" are kept as they are. `targetCode` reads "Target code",
/// `institutionBRINCode` "Institution BRIN code".
String readableClaimKey(String key) {
  final words = key
      .replaceAllMapped(
        RegExp(r"([a-z0-9])([A-Z])|([A-Z])([A-Z][a-z])"),
        (m) => m[1] != null ? "${m[1]} ${m[2]}" : "${m[3]} ${m[4]}",
      )
      .replaceAll("_", " ")
      .split(" ")
      .where((w) => w.isNotEmpty)
      .toList();
  return [
    for (final (i, w) in words.indexed)
      if (w.length > 1 && w == w.toUpperCase())
        w
      else if (i == 0)
        w[0].toUpperCase() + w.substring(1)
      else
        w[0].toLowerCase() + w.substring(1),
  ].join(" ");
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

  Attribute({
    required this.claimPath,
    required this.displayName,
    this.description,
    this.value,
    this.requestedValue,
    this.intentToRetain,
  });

  /// The display name to render in the UI. Falls back to the last non-int
  /// segment of [claimPath], made readable by [readableClaimKey], when the
  /// backend did not supply a display name, so the UI shows the field
  /// identifier instead of an empty label. Int segments (array indices) are
  /// skipped so positions like `["tags", 0]` fall back to "Tags" rather than
  /// "0".
  String get effectiveDisplayName {
    final name = displayName;
    if (name != null && name.isNotEmpty) return name;
    if (claimPath.isEmpty) return name ?? "";
    for (var i = claimPath.length - 1; i >= 0; i--) {
      final seg = claimPath[i];
      if (seg is String) return readableClaimKey(seg);
    }
    return claimPath.join(".");
  }

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
  final bool verified;

  TrustedParty({
    required this.id,
    required this.name,
    required this.url,
    required this.parent,
    required this.verified,
    this.imagePath,
    this.image,
  });

  factory TrustedParty.fromJson(Map<String, dynamic> json) =>
      _$TrustedPartyFromJson(json);

  Map<String, dynamic> toJson() => _$TrustedPartyToJson(this);
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

@JsonSerializable(fieldRename: .snake)
class Credential {
  final String credentialId;
  final String hash;
  final LogoImage? image;
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
    this.issuanceDate,
    this.expiryDate,
  });

  factory Credential.fromJson(Map<String, dynamic> json) =>
      _$CredentialFromJson(json);

  Map<String, dynamic> toJson() => _$CredentialToJson(this);
}

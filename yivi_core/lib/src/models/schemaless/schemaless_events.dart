import "package:json_annotation/json_annotation.dart";

import "../event.dart";
import "../log_entry.dart";

part "schemaless_events.g.dart";

@JsonSerializable(createToJson: false, fieldRename: .snake)
class SchemalessCredentialsEvent extends Event {
  final List<Credential> credentials;

  SchemalessCredentialsEvent({required this.credentials});

  factory SchemalessCredentialsEvent.fromJson(Map<String, dynamic> json) =>
      _$SchemalessCredentialsEventFromJson(json);
}

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

  AttributeValue({
    required this.type,
    this.intValue,
    this.boolValue,
    this.string,
    this.imagePath,
    this.base64Image,
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

  Attribute({
    required this.claimPath,
    required this.displayName,
    this.description,
    this.value,
    this.requestedValue,
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

  factory Attribute.fromJson(Map<String, dynamic> json) =>
      _$AttributeFromJson(json);

  Map<String, dynamic> toJson() => _$AttributeToJson(this);
}

/// How strongly a party is vouched for: the three rungs of irmago's trust
/// ladder. The absence of any evaluation is modelled as a null
/// [TrustedParty.trustLevel], not as a fourth value — absent is not `low`.
enum TrustLevel { low, medium, high }

String trustLevelToString(TrustLevel level) => switch (level) {
  TrustLevel.low => "low",
  TrustLevel.medium => "medium",
  TrustLevel.high => "high",
};

/// Throws on a rung this app does not know, deliberately: a new rung on the
/// wire means irmago and the app are out of lockstep, and silently rendering
/// such a party as levelless — or worse, as vouched for — would hide that.
/// The empty string is irmago's documented "unevaluated" zero value, not an
/// unknown rung, so it maps to null like an absent field.
TrustLevel? stringToTrustLevel(String level) => switch (level) {
  "" => null,
  "low" => TrustLevel.low,
  "medium" => TrustLevel.medium,
  "high" => TrustLevel.high,
  _ => throw Exception("invalid trust level: $level"),
};

TrustLevel? _trustLevelFromJson(String? level) =>
    level == null ? null : stringToTrustLevel(level);

String? _trustLevelToJson(TrustLevel? level) =>
    level == null ? null : trustLevelToString(level);

@JsonSerializable(fieldRename: .snake)
class TrustedParty {
  final String id;
  final String name;
  final String? url;
  final String? imagePath;
  final LogoImage? image;
  final TrustedParty? parent;

  /// Null when irmago evaluated nothing, which is not the same as [
  /// TrustLevel.low]. Whether a rung is good enough is never a property of the
  /// party — it depends on what the session is doing, so ask
  /// `requestorHeaderState` instead of comparing here.
  @JsonKey(fromJson: _trustLevelFromJson, toJson: _trustLevelToJson)
  final TrustLevel? trustLevel;

  TrustedParty({
    required this.id,
    required this.name,
    required this.url,
    required this.parent,
    this.trustLevel,
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

import "package:json_annotation/json_annotation.dart";

import "../event.dart";
import "../log_entry.dart";
import "../translated_value.dart";

part "schemaless_events.g.dart";

@JsonSerializable(createToJson: false, fieldRename: .snake)
class SchemalessCredentialsEvent extends Event {
  final List<Credential> credentials;

  SchemalessCredentialsEvent({required this.credentials});

  factory SchemalessCredentialsEvent.fromJson(Map<String, dynamic> json) =>
      _$SchemalessCredentialsEventFromJson(json);
}

@JsonEnum(alwaysCreate: true, fieldRename: .snake)
enum AttributeType {
  object,
  array,
  translatedString,
  boolean,
  integer,
  image,
  base64Image,
}

@JsonSerializable(fieldRename: .snake)
class AttributeValue {
  final AttributeType type;
  @JsonKey(name: "int")
  final int? intValue;
  @JsonKey(name: "bool")
  final bool? boolValue;
  final TranslatedValue? translatedString;
  final List<AttributeValue>? array;
  final List<Attribute>? object;
  final String? imagePath;
  final String? base64Image;

  AttributeValue({
    required this.type,
    this.intValue,
    this.boolValue,
    this.translatedString,
    this.array,
    this.object,
    this.imagePath,
    this.base64Image,
  });

  /// Whether this value has actual data set (not just a type marker).
  bool get hasConcreteValue =>
      intValue != null ||
      boolValue != null ||
      translatedString != null ||
      array != null ||
      object != null ||
      imagePath != null ||
      base64Image != null;

  factory AttributeValue.fromJson(Map<String, dynamic> json) =>
      _$AttributeValueFromJson(json);

  Map<String, dynamic> toJson() => _$AttributeValueToJson(this);
}

@JsonSerializable(fieldRename: .snake)
class Attribute {
  final String id;
  final TranslatedValue displayName;
  final TranslatedValue? description;
  final AttributeValue? value;
  final AttributeValue? requestedValue;

  Attribute({
    required this.id,
    required this.displayName,
    this.description,
    this.value,
    this.requestedValue,
  });

  factory Attribute.fromJson(Map<String, dynamic> json) =>
      _$AttributeFromJson(json);

  Map<String, dynamic> toJson() => _$AttributeToJson(this);
}

@JsonSerializable(fieldRename: .snake)
class TrustedParty {
  final String id;
  final TranslatedValue name;
  final TranslatedValue? url;
  final String? imagePath;
  final TrustedParty? parent;
  final bool verified;

  TrustedParty({
    required this.id,
    required this.name,
    required this.url,
    required this.parent,
    required this.verified,
    this.imagePath,
  });

  factory TrustedParty.fromJson(Map<String, dynamic> json) =>
      _$TrustedPartyFromJson(json);

  Map<String, dynamic> toJson() => _$TrustedPartyToJson(this);
}

@JsonSerializable(fieldRename: .snake)
class Credential {
  final String credentialId;
  final String hash;
  final String imagePath;
  final TranslatedValue name;
  final TrustedParty issuer;
  final Map<CredentialFormat, String> credentialInstanceIds;
  final Map<CredentialFormat, int?> batchInstanceCountsRemaining;
  final List<Attribute> attributes;
  final int issuanceDate;
  final int expiryDate;
  final bool revoked;
  final bool revocationSupported;
  final TranslatedValue issueUrl;

  Credential({
    required this.credentialId,
    required this.hash,
    required this.imagePath,
    required this.name,
    required this.issuer,
    required this.credentialInstanceIds,
    required this.batchInstanceCountsRemaining,
    required this.attributes,
    required this.issuanceDate,
    required this.expiryDate,
    required this.revoked,
    required this.revocationSupported,
    required this.issueUrl,
  });

  factory Credential.fromJson(Map<String, dynamic> json) =>
      _$CredentialFromJson(json);

  Map<String, dynamic> toJson() => _$CredentialToJson(this);
}

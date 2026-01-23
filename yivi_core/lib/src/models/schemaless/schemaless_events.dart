import "package:json_annotation/json_annotation.dart";

import "../event.dart";
import "../log_entry.dart";
import "../translated_value.dart";

part "schemaless_events.g.dart";

@JsonSerializable(createToJson: false)
class SchemalessCredentialsEvent extends Event {
  @JsonKey(name: "Credentials")
  final List<Credential> credentials;

  SchemalessCredentialsEvent({required this.credentials});

  factory SchemalessCredentialsEvent.fromJson(Map<String, dynamic> json) =>
      _$SchemalessCredentialsEventFromJson(json);
}

@JsonEnum(alwaysCreate: true, fieldRename: .snake)
enum AttributeType {
  object,
  array,
  string,
  translatedString,
  boolean,
  integer,
  image,
  base64Image,
}

@JsonSerializable(createToJson: false)
class AttributeValue {
  @JsonKey(name: "Type")
  final AttributeType type;

  @JsonKey(name: "Data")
  final dynamic data;

  AttributeValue({required this.type, required this.data});

  factory AttributeValue.fromJson(Map<String, dynamic> json) =>
      _$AttributeValueFromJson(json);
}

@JsonSerializable(createToJson: false)
class Attribute {
  @JsonKey(name: "Id")
  final String id;

  @JsonKey(name: "DisplayName")
  final TranslatedValue displayName;

  @JsonKey(name: "Description")
  final TranslatedValue description;

  @JsonKey(name: "Value")
  final AttributeValue value;

  Attribute({
    required this.id,
    required this.displayName,
    required this.description,
    required this.value,
  });

  factory Attribute.fromJson(Map<String, dynamic> json) =>
      _$AttributeFromJson(json);
}

@JsonSerializable(createToJson: false)
class TrustedParty {
  @JsonKey(name: "Id")
  final String id;

  @JsonKey(name: "Name")
  final TranslatedValue name;

  @JsonKey(name: "Url")
  final TranslatedValue url;

  @JsonKey(name: "ImagePath")
  final String imagePath;

  @JsonKey(name: "Parent")
  final TrustedParty? parent;

  TrustedParty({
    required this.id,
    required this.name,
    required this.url,
    required this.imagePath,
    required this.parent,
  });

  factory TrustedParty.fromJson(Map<String, dynamic> json) =>
      _$TrustedPartyFromJson(json);
}

@JsonSerializable(createToJson: false)
class Credential {
  @JsonKey(name: "CredentialId")
  final String credentialId;

  @JsonKey(name: "Hash")
  final String hash;

  @JsonKey(name: "ImagePath")
  final String imagePath;

  @JsonKey(name: "Name")
  final TranslatedValue name;

  @JsonKey(name: "Issuer")
  final TrustedParty issuer;

  @JsonKey(name: "CredentialInstanceIds")
  final Map<CredentialFormat, String> credentialInstanceIds;

  @JsonKey(name: "BatchInstanceCountsRemaining")
  final Map<CredentialFormat, int?> batchInstanceCountsRemaining;

  @JsonKey(name: "Attributes")
  List<Attribute> attributes;

  @JsonKey(name: "IssuanceDate")
  final int issuanceDate;

  @JsonKey(name: "ExpiryDate")
  final int expiryDate;

  @JsonKey(name: "Revoked")
  final bool revoked;

  @JsonKey(name: "RevocationSupported")
  final bool revocationSupported;

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
  });

  factory Credential.fromJson(Map<String, dynamic> json) =>
      _$CredentialFromJson(json);
}

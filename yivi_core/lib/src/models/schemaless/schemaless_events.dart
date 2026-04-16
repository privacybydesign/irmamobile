
import "dart:convert";

import "package:flutter/material.dart";
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
  final TranslatedValue displayName;
  final TranslatedValue? description;
  final AttributeValue? value;
  final AttributeValue? requestedValue;

  Attribute({
    required this.claimPath,
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

  Image? getImageFromBase64() {
    return image?.getImageFromBase64();
  }

  factory TrustedParty.fromJson(Map<String, dynamic> json) =>
      _$TrustedPartyFromJson(json);

  Map<String, dynamic> toJson() => _$TrustedPartyToJson(this);
}

@JsonSerializable(fieldRename: .snake)
class LogoImage {
  final String base64;
  final String? mimeType;

  LogoImage({required this.base64, this.mimeType});

  Image getImageFromBase64() {
    return Image.memory(
      base64Decode(base64),
    );
  }

  factory LogoImage.fromJson(Map<String, dynamic> json) => _$LogoImageFromJson(json);

  Map<String, dynamic> toJson() => _$LogoImageToJson(this);
}

@JsonSerializable(fieldRename: .snake)
class Credential {
  final String credentialId;
  final String hash;
  final String? imagePath;
  final LogoImage? image;
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
    this.imagePath,
    this.image,
  });

  Image? getImageFromBase64() {
      return image?.getImageFromBase64();
  }

  factory Credential.fromJson(Map<String, dynamic> json) =>
      _$CredentialFromJson(json);

  Map<String, dynamic> toJson() => _$CredentialToJson(this);
}

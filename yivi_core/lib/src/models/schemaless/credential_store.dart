// AttributeDescriptor is a description of an attribute without a value
import "package:json_annotation/json_annotation.dart";

import "../translated_value.dart";
import "schemaless_events.dart";

part "credential_store.g.dart";

@JsonSerializable(createToJson: false)
class AttributeDescriptor {
  @JsonKey(name: "Id")
  final String id;

  @JsonKey(name: "Name")
  final TranslatedValue name;

  @JsonKey(name: "Type")
  final AttributeType type;

  @JsonKey(name: "Nested")
  final List<AttributeDescriptor> nested;

  AttributeDescriptor({
    required this.id,
    required this.name,
    required this.type,
    required this.nested,
  });

  AttributeDescriptor fromJson(Map<String, dynamic> json) =>
      _$AttributeDescriptorFromJson(json);
}

@JsonSerializable(createToJson: false)
class CredentialDescriptor {
  @JsonKey(name: "CredentialId")
  final String credentialId;

  @JsonKey(name: "Name")
  final TranslatedValue name;

  @JsonKey(name: "Issuer")
  final TrustedParty issuer;

  @JsonKey(name: "Category")
  final TranslatedValue? category;

  @JsonKey(name: "ImagePath")
  final String imagePath;

  @JsonKey(name: "Attributes")
  final List<AttributeDescriptor> attributes;

  @JsonKey(name: "IssueURL")
  final TranslatedValue? issueURL;

  CredentialDescriptor({
    required this.credentialId,
    required this.name,
    required this.issuer,
    required this.category,
    required this.imagePath,
    required this.attributes,
    required this.issueURL,
  });

  CredentialDescriptor fromJson(Map<String, dynamic> json) =>
      _$CredentialDescriptorFromJson(json);
}

@JsonSerializable(createToJson: false)
class CredentialStoreItem {
  @JsonKey(name: "Credential")
  final CredentialDescriptor credential;
  @JsonKey(name: "Faq")
  final Faq faq;

  CredentialStoreItem({required this.credential, required this.faq});

  CredentialStoreItem fromJson(Map<String, dynamic> json) =>
      _$CredentialStoreItemFromJson(json);
}

@JsonSerializable(createToJson: false)
class Faq {
  @JsonKey(name: "Into")
  final TranslatedValue intro;

  @JsonKey(name: "Purpose")
  final TranslatedValue purpose;

  @JsonKey(name: "Content")
  final TranslatedValue content;

  @JsonKey(name: "HowTo")
  final TranslatedValue howTo;

  Faq({
    required this.intro,
    required this.purpose,
    required this.content,
    required this.howTo,
  });

  Faq fromJson(Map<String, dynamic> json) => _$FaqFromJson(json);
}

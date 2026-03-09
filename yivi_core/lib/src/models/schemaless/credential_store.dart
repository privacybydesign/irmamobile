import "package:json_annotation/json_annotation.dart";

import "../event.dart";
import "../translated_value.dart";
import "schemaless_events.dart";

part "credential_store.g.dart";

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class SchemalessCredentialStoreEvent extends Event {
  final List<CredentialStoreItem> credentials;

  SchemalessCredentialStoreEvent({required this.credentials});

  factory SchemalessCredentialStoreEvent.fromJson(Map<String, dynamic> json) =>
      _$SchemalessCredentialStoreEventFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CredentialDescriptor {
  final String credentialId;
  final TranslatedValue name;
  final TrustedParty issuer;
  final TranslatedValue? category;
  final String imagePath;
  final List<Attribute> attributes;

  @JsonKey(name: "issue_url")
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

  factory CredentialDescriptor.fromJson(Map<String, dynamic> json) =>
      _$CredentialDescriptorFromJson(json);

  Map<String, dynamic> toJson() => _$CredentialDescriptorToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CredentialStoreItem {
  final CredentialDescriptor credential;
  final Faq faq;

  CredentialStoreItem({required this.credential, required this.faq});

  factory CredentialStoreItem.fromJson(Map<String, dynamic> json) =>
      _$CredentialStoreItemFromJson(json);

  Map<String, dynamic> toJson() => _$CredentialStoreItemToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Faq {
  final TranslatedValue intro;

  final TranslatedValue purpose;

  final TranslatedValue content;

  final TranslatedValue howTo;

  Faq({
    required this.intro,
    required this.purpose,
    required this.content,
    required this.howTo,
  });

  factory Faq.fromJson(Map<String, dynamic> json) => _$FaqFromJson(json);

  Map<String, dynamic> toJson() => _$FaqToJson(this);
}

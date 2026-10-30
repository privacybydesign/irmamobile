import "package:json_annotation/json_annotation.dart";

import "../event.dart";
import "../log_entry.dart";
import "schemaless_events.dart";

part "credential_store.g.dart";

@JsonSerializable(createToJson: false, fieldRename: .snake)
class SchemalessCredentialStoreEvent extends Event {
  final List<CredentialStoreItem> credentials;

  SchemalessCredentialStoreEvent({required this.credentials});

  factory SchemalessCredentialStoreEvent.fromJson(Map<String, dynamic> json) =>
      _$SchemalessCredentialStoreEventFromJson(json);
}

@JsonSerializable(fieldRename: .snake)
class CredentialDescriptor {
  final String credentialId;
  final String name;
  final TrustedParty issuer;
  final String? category;
  final LogoImage? image;
  final List<Attribute> attributes;

  @JsonKey(name: "issue_url")
  final String? issueURL;

  /// The format the credential is offered or requested in; null when the
  /// descriptor is not tied to one format, as for an IRMA credential type, or
  /// when irmago is too old to send it.
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final CredentialFormat? format;

  CredentialDescriptor({
    required this.credentialId,
    required this.name,
    required this.issuer,
    required this.category,
    required this.attributes,
    required this.issueURL,
    this.image,
    this.format,
  });

  factory CredentialDescriptor.fromJson(Map<String, dynamic> json) =>
      _$CredentialDescriptorFromJson(json);

  Map<String, dynamic> toJson() => _$CredentialDescriptorToJson(this);
}

@JsonSerializable(fieldRename: .snake)
class CredentialStoreItem {
  final CredentialDescriptor credential;
  final Faq faq;

  CredentialStoreItem({required this.credential, required this.faq});

  factory CredentialStoreItem.fromJson(Map<String, dynamic> json) =>
      _$CredentialStoreItemFromJson(json);

  Map<String, dynamic> toJson() => _$CredentialStoreItemToJson(this);
}

@JsonSerializable(fieldRename: .snake)
class Faq {
  final String? intro;
  final String? purpose;
  final String? content;
  final String? howTo;

  Faq({
    required this.intro,
    required this.purpose,
    required this.content,
    required this.howTo,
  });

  factory Faq.fromJson(Map<String, dynamic> json) => _$FaqFromJson(json);

  Map<String, dynamic> toJson() => _$FaqToJson(this);
}

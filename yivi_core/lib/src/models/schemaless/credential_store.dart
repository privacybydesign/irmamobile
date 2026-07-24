import "package:json_annotation/json_annotation.dart";

import "../event.dart";
import "../translated_value.dart";
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
  final TranslatedValue name;
  final TrustedParty issuer;
  final TranslatedValue? category;
  final LogoImage? image;
  final List<Attribute> attributes;

  @JsonKey(name: "issue_url")
  final TranslatedValue? issueURL;

  CredentialDescriptor({
    required this.credentialId,
    required this.name,
    required this.issuer,
    required this.category,
    required this.attributes,
    required this.issueURL,
    this.image,
  });

  factory CredentialDescriptor.fromJson(Map<String, dynamic> json) =>
      _$CredentialDescriptorFromJson(json);

  Map<String, dynamic> toJson() => _$CredentialDescriptorToJson(this);

  /// The concrete values the verifier accepts for this credential's
  /// attributes, if any, in attribute order. These are the values shown to
  /// the user on the disclosure screen (see
  /// [YiviCredentialCard.fromDescriptor]); the obtain flow (e.g. the
  /// email-loading screen) locks its input to these values so the user can
  /// only choose one of them, not enter a different one. This is a list
  /// because OpenID4VP (DCQL, section 6) allows a verifier to accept several
  /// values for one claim; the IRMA protocol allows a single required value,
  /// so today the bridge supplies at most one value per attribute.
  ///
  /// A verifier may constrain several attributes at once (e.g. both `email`
  /// and `domain`), so consumers must select the values relevant to them —
  /// the email flow only locks to values that are email addresses. Returns
  /// an empty list when the verifier did not request specific values.
  List<String> get requestedValues {
    final values = <String>[];
    for (final attribute in attributes) {
      final value = attribute.requestedValue?.string;
      if (value != null && value.isNotEmpty) {
        values.add(value);
      }
    }
    return values;
  }
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

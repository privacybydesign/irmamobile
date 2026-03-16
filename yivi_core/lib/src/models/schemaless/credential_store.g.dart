// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credential_store.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchemalessCredentialStoreEvent _$SchemalessCredentialStoreEventFromJson(
  Map<String, dynamic> json,
) => SchemalessCredentialStoreEvent(
  credentials: (json['credentials'] as List<dynamic>)
      .map((e) => CredentialStoreItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

CredentialDescriptor _$CredentialDescriptorFromJson(
  Map<String, dynamic> json,
) => CredentialDescriptor(
  credentialId: json['credential_id'] as String,
  name: TranslatedValue.fromJson(json['name'] as Map<String, dynamic>?),
  issuer: TrustedParty.fromJson(json['issuer'] as Map<String, dynamic>),
  category: json['category'] == null
      ? null
      : TranslatedValue.fromJson(json['category'] as Map<String, dynamic>?),
  imagePath: json['image_path'] as String?,
  attributes: (json['attributes'] as List<dynamic>)
      .map((e) => Attribute.fromJson(e as Map<String, dynamic>))
      .toList(),
  issueURL: json['issue_url'] == null
      ? null
      : TranslatedValue.fromJson(json['issue_url'] as Map<String, dynamic>?),
);

Map<String, dynamic> _$CredentialDescriptorToJson(
  CredentialDescriptor instance,
) => <String, dynamic>{
  'credential_id': instance.credentialId,
  'name': instance.name,
  'issuer': instance.issuer,
  'category': instance.category,
  'image_path': instance.imagePath,
  'attributes': instance.attributes,
  'issue_url': instance.issueURL,
};

CredentialStoreItem _$CredentialStoreItemFromJson(Map<String, dynamic> json) =>
    CredentialStoreItem(
      credential: CredentialDescriptor.fromJson(
        json['credential'] as Map<String, dynamic>,
      ),
      faq: Faq.fromJson(json['faq'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CredentialStoreItemToJson(
  CredentialStoreItem instance,
) => <String, dynamic>{'credential': instance.credential, 'faq': instance.faq};

Faq _$FaqFromJson(Map<String, dynamic> json) => Faq(
  intro: TranslatedValue.fromJson(json['intro'] as Map<String, dynamic>?),
  purpose: TranslatedValue.fromJson(json['purpose'] as Map<String, dynamic>?),
  content: TranslatedValue.fromJson(json['content'] as Map<String, dynamic>?),
  howTo: TranslatedValue.fromJson(json['how_to'] as Map<String, dynamic>?),
);

Map<String, dynamic> _$FaqToJson(Faq instance) => <String, dynamic>{
  'intro': instance.intro,
  'purpose': instance.purpose,
  'content': instance.content,
  'how_to': instance.howTo,
};

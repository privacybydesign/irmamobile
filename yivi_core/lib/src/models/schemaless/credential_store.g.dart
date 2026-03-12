// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credential_store.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchemalessCredentialStoreEvent _$SchemalessCredentialStoreEventFromJson(
  Map<String, dynamic> json,
) => SchemalessCredentialStoreEvent(
  credentials: (json['Credentials'] as List<dynamic>)
      .map((e) => CredentialStoreItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

AttributeDescriptor _$AttributeDescriptorFromJson(Map<String, dynamic> json) =>
    AttributeDescriptor(
      id: json['Id'] as String,
      name: TranslatedValue.fromJson(json['Name'] as Map<String, dynamic>?),
      type: $enumDecode(_$AttributeTypeEnumMap, json['Type']),
      nested:
          (json['Nested'] as List<dynamic>?)
              ?.map(
                (e) => AttributeDescriptor.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );

Map<String, dynamic> _$AttributeDescriptorToJson(
  AttributeDescriptor instance,
) => <String, dynamic>{
  'Id': instance.id,
  'Name': instance.name,
  'Type': _$AttributeTypeEnumMap[instance.type]!,
  'Nested': instance.nested,
};

const _$AttributeTypeEnumMap = {
  AttributeType.object: 'object',
  AttributeType.array: 'array',
  AttributeType.string: 'string',
  AttributeType.translatedString: 'translated_string',
  AttributeType.boolean: 'boolean',
  AttributeType.integer: 'integer',
  AttributeType.image: 'image',
  AttributeType.base64Image: 'base64_image',
};

CredentialDescriptor _$CredentialDescriptorFromJson(
  Map<String, dynamic> json,
) => CredentialDescriptor(
  credentialId: json['CredentialId'] as String,
  name: TranslatedValue.fromJson(json['Name'] as Map<String, dynamic>?),
  issuer: TrustedParty.fromJson(json['Issuer'] as Map<String, dynamic>),
  category: json['Category'] == null
      ? null
      : TranslatedValue.fromJson(json['Category'] as Map<String, dynamic>?),
  imagePath: json['ImagePath'] as String,
  attributes: (json['Attributes'] as List<dynamic>)
      .map((e) => AttributeDescriptor.fromJson(e as Map<String, dynamic>))
      .toList(),
  issueURL: json['IssueURL'] == null
      ? null
      : TranslatedValue.fromJson(json['IssueURL'] as Map<String, dynamic>?),
);

Map<String, dynamic> _$CredentialDescriptorToJson(
  CredentialDescriptor instance,
) => <String, dynamic>{
  'CredentialId': instance.credentialId,
  'Name': instance.name,
  'Issuer': instance.issuer,
  'Category': instance.category,
  'ImagePath': instance.imagePath,
  'Attributes': instance.attributes,
  'IssueURL': instance.issueURL,
};

CredentialStoreItem _$CredentialStoreItemFromJson(Map<String, dynamic> json) =>
    CredentialStoreItem(
      credential: CredentialDescriptor.fromJson(
        json['Credential'] as Map<String, dynamic>,
      ),
      faq: Faq.fromJson(json['Faq'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CredentialStoreItemToJson(
  CredentialStoreItem instance,
) => <String, dynamic>{'Credential': instance.credential, 'Faq': instance.faq};

Faq _$FaqFromJson(Map<String, dynamic> json) => Faq(
  intro: TranslatedValue.fromJson(json['Into'] as Map<String, dynamic>?),
  purpose: TranslatedValue.fromJson(json['Purpose'] as Map<String, dynamic>?),
  content: TranslatedValue.fromJson(json['Content'] as Map<String, dynamic>?),
  howTo: TranslatedValue.fromJson(json['HowTo'] as Map<String, dynamic>?),
);

Map<String, dynamic> _$FaqToJson(Faq instance) => <String, dynamic>{
  'Into': instance.intro,
  'Purpose': instance.purpose,
  'Content': instance.content,
  'HowTo': instance.howTo,
};

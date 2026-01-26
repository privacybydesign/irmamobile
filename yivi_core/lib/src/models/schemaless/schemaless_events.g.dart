// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schemaless_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchemalessCredentialsEvent _$SchemalessCredentialsEventFromJson(
  Map<String, dynamic> json,
) => SchemalessCredentialsEvent(
  credentials: (json['Credentials'] as List<dynamic>)
      .map((e) => Credential.fromJson(e as Map<String, dynamic>))
      .toList(),
);

AttributeValue _$AttributeValueFromJson(Map<String, dynamic> json) =>
    AttributeValue(
      type: $enumDecode(_$AttributeTypeEnumMap, json['Type']),
      data: json['Data'],
    );

Map<String, dynamic> _$AttributeValueToJson(AttributeValue instance) =>
    <String, dynamic>{
      'Type': _$AttributeTypeEnumMap[instance.type]!,
      'Data': instance.data,
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

Attribute _$AttributeFromJson(Map<String, dynamic> json) => Attribute(
  id: json['Id'] as String,
  displayName: TranslatedValue.fromJson(
    json['DisplayName'] as Map<String, dynamic>?,
  ),
  description: TranslatedValue.fromJson(
    json['Description'] as Map<String, dynamic>?,
  ),
  value: AttributeValue.fromJson(json['Value'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AttributeToJson(Attribute instance) => <String, dynamic>{
  'Id': instance.id,
  'DisplayName': instance.displayName,
  'Description': instance.description,
  'Value': instance.value,
};

TrustedParty _$TrustedPartyFromJson(Map<String, dynamic> json) => TrustedParty(
  id: json['Id'] as String,
  name: TranslatedValue.fromJson(json['Name'] as Map<String, dynamic>?),
  url: json['Url'] == null
      ? null
      : TranslatedValue.fromJson(json['Url'] as Map<String, dynamic>?),
  imagePath: json['ImagePath'] as String?,
  parent: json['Parent'] == null
      ? null
      : TrustedParty.fromJson(json['Parent'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TrustedPartyToJson(TrustedParty instance) =>
    <String, dynamic>{
      'Id': instance.id,
      'Name': instance.name,
      'Url': instance.url,
      'ImagePath': instance.imagePath,
      'Parent': instance.parent,
    };

Credential _$CredentialFromJson(Map<String, dynamic> json) => Credential(
  credentialId: json['CredentialId'] as String,
  hash: json['Hash'] as String,
  imagePath: json['ImagePath'] as String,
  name: TranslatedValue.fromJson(json['Name'] as Map<String, dynamic>?),
  issuer: TrustedParty.fromJson(json['Issuer'] as Map<String, dynamic>),
  credentialInstanceIds: (json['CredentialInstanceIds'] as Map<String, dynamic>)
      .map(
        (k, e) =>
            MapEntry($enumDecode(_$CredentialFormatEnumMap, k), e as String),
      ),
  batchInstanceCountsRemaining:
      (json['BatchInstanceCountsRemaining'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
          $enumDecode(_$CredentialFormatEnumMap, k),
          (e as num?)?.toInt(),
        ),
      ),
  attributes: (json['Attributes'] as List<dynamic>)
      .map((e) => Attribute.fromJson(e as Map<String, dynamic>))
      .toList(),
  issuanceDate: (json['IssuanceDate'] as num).toInt(),
  expiryDate: (json['ExpiryDate'] as num).toInt(),
  revoked: json['Revoked'] as bool,
  revocationSupported: json['RevocationSupported'] as bool,
  issueUrl: TranslatedValue.fromJson(json['IssueURL'] as Map<String, dynamic>?),
);

Map<String, dynamic> _$CredentialToJson(Credential instance) =>
    <String, dynamic>{
      'CredentialId': instance.credentialId,
      'Hash': instance.hash,
      'ImagePath': instance.imagePath,
      'Name': instance.name,
      'Issuer': instance.issuer,
      'CredentialInstanceIds': instance.credentialInstanceIds.map(
        (k, e) => MapEntry(_$CredentialFormatEnumMap[k]!, e),
      ),
      'BatchInstanceCountsRemaining': instance.batchInstanceCountsRemaining.map(
        (k, e) => MapEntry(_$CredentialFormatEnumMap[k]!, e),
      ),
      'Attributes': instance.attributes,
      'IssuanceDate': instance.issuanceDate,
      'ExpiryDate': instance.expiryDate,
      'Revoked': instance.revoked,
      'RevocationSupported': instance.revocationSupported,
      'IssueURL': instance.issueUrl,
    };

const _$CredentialFormatEnumMap = {
  CredentialFormat.idemix: 'idemix',
  CredentialFormat.sdjwtvc: 'dc+sd-jwt',
};

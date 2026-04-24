// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schemaless_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchemalessCredentialsEvent _$SchemalessCredentialsEventFromJson(
  Map<String, dynamic> json,
) => SchemalessCredentialsEvent(
  credentials: (json['credentials'] as List<dynamic>)
      .map((e) => Credential.fromJson(e as Map<String, dynamic>))
      .toList(),
);

AttributeValue _$AttributeValueFromJson(Map<String, dynamic> json) =>
    AttributeValue(
      type: $enumDecode(_$AttributeTypeEnumMap, json['type']),
      intValue: (json['int'] as num?)?.toInt(),
      boolValue: json['bool'] as bool?,
      string: json['string'] as String?,
      imagePath: json['image_path'] as String?,
      base64Image: json['base64_image'] as String?,
    );

Map<String, dynamic> _$AttributeValueToJson(AttributeValue instance) =>
    <String, dynamic>{
      'type': _$AttributeTypeEnumMap[instance.type]!,
      'int': instance.intValue,
      'bool': instance.boolValue,
      'string': instance.string,
      'image_path': instance.imagePath,
      'base64_image': instance.base64Image,
    };

const _$AttributeTypeEnumMap = {
  AttributeType.string: 'string',
  AttributeType.boolean: 'boolean',
  AttributeType.integer: 'integer',
  AttributeType.image: 'image',
  AttributeType.base64Image: 'base64_image',
};

Attribute _$AttributeFromJson(Map<String, dynamic> json) => Attribute(
  claimPath: json['claim_path'] as List<dynamic>,
  displayName: TranslatedValue.fromJson(
    json['display_name'] as Map<String, dynamic>?,
  ),
  description: json['description'] == null
      ? null
      : TranslatedValue.fromJson(json['description'] as Map<String, dynamic>?),
  value: json['value'] == null
      ? null
      : AttributeValue.fromJson(json['value'] as Map<String, dynamic>),
  requestedValue: json['requested_value'] == null
      ? null
      : AttributeValue.fromJson(
          json['requested_value'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$AttributeToJson(Attribute instance) => <String, dynamic>{
  'claim_path': instance.claimPath,
  'display_name': instance.displayName,
  'description': instance.description,
  'value': instance.value,
  'requested_value': instance.requestedValue,
};

TrustedParty _$TrustedPartyFromJson(Map<String, dynamic> json) => TrustedParty(
  id: json['id'] as String,
  name: TranslatedValue.fromJson(json['name'] as Map<String, dynamic>?),
  url: json['url'] == null
      ? null
      : TranslatedValue.fromJson(json['url'] as Map<String, dynamic>?),
  parent: json['parent'] == null
      ? null
      : TrustedParty.fromJson(json['parent'] as Map<String, dynamic>),
  verified: json['verified'] as bool,
  imagePath: json['image_path'] as String?,
  image: json['image'] == null
      ? null
      : LogoImage.fromJson(json['image'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TrustedPartyToJson(TrustedParty instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'url': instance.url,
      'image_path': instance.imagePath,
      'image': instance.image,
      'parent': instance.parent,
      'verified': instance.verified,
    };

LogoImage _$LogoImageFromJson(Map<String, dynamic> json) => LogoImage(
  base64: json['base64'] as String,
  mimeType: json['mime_type'] as String?,
);

Map<String, dynamic> _$LogoImageToJson(LogoImage instance) => <String, dynamic>{
  'base64': instance.base64,
  'mime_type': instance.mimeType,
};

Credential _$CredentialFromJson(Map<String, dynamic> json) => Credential(
  credentialId: json['credential_id'] as String,
  hash: json['hash'] as String,
  name: TranslatedValue.fromJson(json['name'] as Map<String, dynamic>?),
  issuer: TrustedParty.fromJson(json['issuer'] as Map<String, dynamic>),
  credentialInstanceIds:
      (json['credential_instance_ids'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry($enumDecode(_$CredentialFormatEnumMap, k), e as String),
      ),
  batchInstanceCountsRemaining:
      (json['batch_instance_counts_remaining'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
          $enumDecode(_$CredentialFormatEnumMap, k),
          (e as num?)?.toInt(),
        ),
      ),
  attributes: (json['attributes'] as List<dynamic>)
      .map((e) => Attribute.fromJson(e as Map<String, dynamic>))
      .toList(),
  issuanceDate: (json['issuance_date'] as num).toInt(),
  expiryDate: (json['expiry_date'] as num).toInt(),
  revoked: json['revoked'] as bool,
  revocationSupported: json['revocation_supported'] as bool,
  issueUrl: TranslatedValue.fromJson(
    json['issue_url'] as Map<String, dynamic>?,
  ),
  imagePath: json['image_path'] as String?,
  image: json['image'] == null
      ? null
      : LogoImage.fromJson(json['image'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CredentialToJson(Credential instance) =>
    <String, dynamic>{
      'credential_id': instance.credentialId,
      'hash': instance.hash,
      'image_path': instance.imagePath,
      'image': instance.image,
      'name': instance.name,
      'issuer': instance.issuer,
      'credential_instance_ids': instance.credentialInstanceIds.map(
        (k, e) => MapEntry(_$CredentialFormatEnumMap[k]!, e),
      ),
      'batch_instance_counts_remaining': instance.batchInstanceCountsRemaining
          .map((k, e) => MapEntry(_$CredentialFormatEnumMap[k]!, e)),
      'attributes': instance.attributes,
      'issuance_date': instance.issuanceDate,
      'expiry_date': instance.expiryDate,
      'revoked': instance.revoked,
      'revocation_supported': instance.revocationSupported,
      'issue_url': instance.issueUrl,
    };

const _$CredentialFormatEnumMap = {
  CredentialFormat.idemix: 'idemix',
  CredentialFormat.sdjwtvc: 'dc+sd-jwt',
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credentials.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CredentialTypeInfo _$CredentialTypeInfoFromJson(Map<String, dynamic> json) =>
    CredentialTypeInfo(
      issuerName: TranslatedValue.fromJson(
        json['issuer_name'] as Map<String, dynamic>?,
      ),
      name: TranslatedValue.fromJson(json['name'] as Map<String, dynamic>?),
      verifiableCredentialType: json['verifiable_credential_type'] as String,
      attributes: (json['attributes'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, TranslatedValue.fromJson(e as Map<String, dynamic>?)),
      ),
      credentialFormat: $enumDecode(
        _$CredentialFormatEnumMap,
        json['credential_format'],
      ),
    );

const _$CredentialFormatEnumMap = {
  CredentialFormat.idemix: 'idemix',
  CredentialFormat.sdjwtvc: 'dc+sd-jwt',
};

RawCredential _$RawCredentialFromJson(Map<String, dynamic> json) =>
    RawCredential(
      id: json['id'] as String,
      issuerId: json['issuer_id'] as String,
      schemeManagerId: json['scheme_manager_id'] as String,
      signedOn: (json['signed_on'] as num).toInt(),
      expires: (json['expires'] as num).toInt(),
      attributes: (json['attributes'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, TranslatedValue.fromJson(e as Map<String, dynamic>?)),
      ),
      hash: json['hash'] as String,
      revoked: json['revoked'] as bool,
      revocationSupported: json['revocation_supported'] as bool,
      format: $enumDecode(_$CredentialFormatEnumMap, json['format']),
      instanceCount: (json['instance_count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RawCredentialToJson(RawCredential instance) =>
    <String, dynamic>{
      'id': instance.id,
      'issuer_id': instance.issuerId,
      'scheme_manager_id': instance.schemeManagerId,
      'signed_on': instance.signedOn,
      'expires': instance.expires,
      'attributes': instance.attributes,
      'hash': instance.hash,
      'revoked': instance.revoked,
      'revocation_supported': instance.revocationSupported,
      'format': _$CredentialFormatEnumMap[instance.format]!,
      'instance_count': instance.instanceCount,
    };

RawMultiFormatCredential _$RawMultiFormatCredentialFromJson(
  Map<String, dynamic> json,
) => RawMultiFormatCredential(
  id: json['id'] as String,
  issuerId: json['issuer_id'] as String,
  schemeManagerId: json['scheme_manager_id'] as String,
  attributes: (json['attributes'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, TranslatedValue.fromJson(e as Map<String, dynamic>?)),
  ),
  hashByFormat: (json['hash_by_format'] as Map<String, dynamic>).map(
    (k, e) => MapEntry($enumDecode(_$CredentialFormatEnumMap, k), e as String),
  ),
  signedOn: (json['signed_on'] as num).toInt(),
  expires: (json['expires'] as num).toInt(),
  revoked: json['revoked'] as bool,
  instanceCount: (json['instance_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$RawMultiFormatCredentialToJson(
  RawMultiFormatCredential instance,
) => <String, dynamic>{
  'id': instance.id,
  'issuer_id': instance.issuerId,
  'scheme_manager_id': instance.schemeManagerId,
  'revoked': instance.revoked,
  'attributes': instance.attributes,
  'hash_by_format': instance.hashByFormat.map(
    (k, e) => MapEntry(_$CredentialFormatEnumMap[k]!, e),
  ),
  'signed_on': instance.signedOn,
  'expires': instance.expires,
  'instance_count': instance.instanceCount,
};

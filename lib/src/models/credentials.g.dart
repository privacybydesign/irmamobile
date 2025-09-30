// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credentials.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RawCredential _$RawCredentialFromJson(Map<String, dynamic> json) => RawCredential(
      id: json['ID'] as String,
      issuerId: json['IssuerID'] as String,
      schemeManagerId: json['SchemeManagerID'] as String,
      signedOn: (json['SignedOn'] as num).toInt(),
      expires: (json['Expires'] as num).toInt(),
      attributes: (json['Attributes'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, TranslatedValue.fromJson(e as Map<String, dynamic>?)),
      ),
      hash: json['Hash'] as String,
      revoked: json['Revoked'] as bool,
      revocationSupported: json['RevocationSupported'] as bool,
      format: stringToCredentialFormat(json['CredentialFormat'] as String),
      instanceCount: (json['InstanceCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RawCredentialToJson(RawCredential instance) => <String, dynamic>{
      'ID': instance.id,
      'IssuerID': instance.issuerId,
      'SchemeManagerID': instance.schemeManagerId,
      'SignedOn': instance.signedOn,
      'Expires': instance.expires,
      'Attributes': instance.attributes,
      'Hash': instance.hash,
      'Revoked': instance.revoked,
      'RevocationSupported': instance.revocationSupported,
      'CredentialFormat': credentialFormatToString(instance.format),
      'InstanceCount': instance.instanceCount,
    };

RawMultiFormatCredential _$RawMultiFormatCredentialFromJson(Map<String, dynamic> json) => RawMultiFormatCredential(
      id: json['ID'] as String,
      issuerId: json['IssuerID'] as String,
      schemeManagerId: json['SchemeManagerID'] as String,
      attributes: (json['Attributes'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, TranslatedValue.fromJson(e as Map<String, dynamic>?)),
      ),
      hashByFormat: parseHashByFormat(json['HashByFormat'] as Map<String, dynamic>),
      signedOn: (json['SignedOn'] as num).toInt(),
      expires: (json['Expires'] as num).toInt(),
      revoked: json['Revoked'] as bool,
      instanceCount: (json['InstanceCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RawMultiFormatCredentialToJson(RawMultiFormatCredential instance) => <String, dynamic>{
      'ID': instance.id,
      'IssuerID': instance.issuerId,
      'SchemeManagerID': instance.schemeManagerId,
      'Revoked': instance.revoked,
      'Attributes': instance.attributes,
      'HashByFormat': instance.hashByFormat.map((k, e) => MapEntry(_$CredentialFormatEnumMap[k]!, e)),
      'SignedOn': instance.signedOn,
      'Expires': instance.expires,
      'InstanceCount': instance.instanceCount,
    };

const _$CredentialFormatEnumMap = {
  CredentialFormat.idemix: 'idemix',
  CredentialFormat.sdjwtvc: 'sdjwtvc',
};

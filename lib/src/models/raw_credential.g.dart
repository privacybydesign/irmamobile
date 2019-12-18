// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raw_credential.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RawCredential _$RawCredentialFromJson(Map<String, dynamic> json) {
  return RawCredential(
    id: json['ID'] as String,
    issuerId: json['IssuerID'] as String,
    schemeManagerId: json['SchemeManagerID'] as String,
    signedOn: json['SignedOn'] as int,
    expires: json['Expires'] as int,
    attributes: (json['Attributes'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, Map<String, String>.from(e as Map)),
    ),
    hash: json['Hash'] as String,
  );
}

Map<String, dynamic> _$RawCredentialToJson(RawCredential instance) =>
    <String, dynamic>{
      'ID': instance.id,
      'IssuerID': instance.issuerId,
      'SchemeManagerID': instance.schemeManagerId,
      'SignedOn': instance.signedOn,
      'Expires': instance.expires,
      'Attributes': instance.attributes,
      'Hash': instance.hash,
    };

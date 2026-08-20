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

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credential_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CredentialsEvent _$CredentialsEventFromJson(Map<String, dynamic> json) => CredentialsEvent(
      credentials:
          (json['Credentials'] as List<dynamic>).map((e) => RawCredential.fromJson(e as Map<String, dynamic>)).toList(),
    );

Map<String, dynamic> _$CredentialsEventToJson(CredentialsEvent instance) => <String, dynamic>{
      'Credentials': instance.credentials,
    };

DeleteCredentialEvent _$DeleteCredentialEventFromJson(Map<String, dynamic> json) => DeleteCredentialEvent(
      hashByFormat: (json['HashByFormat'] as Map<String, dynamic>).map(
        (k, e) => MapEntry($enumDecode(_$CredentialFormatEnumMap, k), e as String),
      ),
    );

Map<String, dynamic> _$DeleteCredentialEventToJson(DeleteCredentialEvent instance) => <String, dynamic>{
      'HashByFormat': hashByFormatToString(instance.hashByFormat),
    };

const _$CredentialFormatEnumMap = {
  CredentialFormat.idemix: 'idemix',
  CredentialFormat.sdjwtvc: 'sdjwtvc',
};

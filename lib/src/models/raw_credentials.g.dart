// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raw_credentials.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RawCredentials _$RawCredentialsFromJson(Map<String, dynamic> json) {
  return RawCredentials(
    credentials: (json['Credentials'] as List).map((e) => RawCredential.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

Map<String, dynamic> _$RawCredentialsToJson(RawCredentials instance) => <String, dynamic>{
      'Credentials': instance.credentials,
    };

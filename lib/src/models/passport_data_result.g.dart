// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'passport_data_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PassportDataResult _$PassportDataResultFromJson(Map<String, dynamic> json) => PassportDataResult(
      dataGroups: Map<String, String>.from(json['data_groups'] as Map),
      efSod: json['ef_sod'] as String,
      sessionId: json['session_id'] as String?,
      nonce: const Uint8ListConverter().fromJson(json['nonce'] as String?),
      aaSignature: const Uint8ListConverter().fromJson(json['aa_signature'] as String?),
    );

Map<String, dynamic> _$PassportDataResultToJson(PassportDataResult instance) => <String, dynamic>{
      'data_groups': instance.dataGroups,
      'ef_sod': instance.efSod,
      'session_id': instance.sessionId,
      'nonce': const Uint8ListConverter().toJson(instance.nonce),
      'aa_signature': const Uint8ListConverter().toJson(instance.aaSignature),
    };

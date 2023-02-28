// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheme_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstallSchemeEvent _$InstallSchemeEventFromJson(Map<String, dynamic> json) => InstallSchemeEvent(
      url: json['URL'] as String,
      publicKey: json['PublicKey'] as String,
    );

Map<String, dynamic> _$InstallSchemeEventToJson(InstallSchemeEvent instance) => <String, dynamic>{
      'URL': instance.url,
      'PublicKey': instance.publicKey,
    };

RemoveSchemeEvent _$RemoveSchemeEventFromJson(Map<String, dynamic> json) => RemoveSchemeEvent(
      schemeId: json['SchemeID'] as String,
    );

Map<String, dynamic> _$RemoveSchemeEventToJson(RemoveSchemeEvent instance) => <String, dynamic>{
      'SchemeID': instance.schemeId,
    };

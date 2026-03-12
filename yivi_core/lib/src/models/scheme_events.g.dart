// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheme_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstallSchemeEvent _$InstallSchemeEventFromJson(Map<String, dynamic> json) =>
    InstallSchemeEvent(
      url: json['url'] as String,
      publicKey: json['public_key'] as String,
    );

Map<String, dynamic> _$InstallSchemeEventToJson(InstallSchemeEvent instance) =>
    <String, dynamic>{'url': instance.url, 'public_key': instance.publicKey};

RemoveSchemeEvent _$RemoveSchemeEventFromJson(Map<String, dynamic> json) =>
    RemoveSchemeEvent(schemeId: json['scheme_id'] as String);

Map<String, dynamic> _$RemoveSchemeEventToJson(RemoveSchemeEvent instance) =>
    <String, dynamic>{'scheme_id': instance.schemeId};

RemoveRequestorSchemeEvent _$RemoveRequestorSchemeEventFromJson(
  Map<String, dynamic> json,
) => RemoveRequestorSchemeEvent(schemeId: json['scheme_id'] as String);

Map<String, dynamic> _$RemoveRequestorSchemeEventToJson(
  RemoveRequestorSchemeEvent instance,
) => <String, dynamic>{'scheme_id': instance.schemeId};

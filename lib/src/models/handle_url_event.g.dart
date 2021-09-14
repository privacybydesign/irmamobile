// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'handle_url_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HandleURLEvent _$HandleURLEventFromJson(Map<String, dynamic> json) {
  return HandleURLEvent(
    url: json['url'] as String,
    isInitialUrl: json['isInitialURL'] as bool? ?? false,
  );
}

Map<String, dynamic> _$HandleURLEventToJson(HandleURLEvent instance) => <String, dynamic>{
      'isInitialURL': instance.isInitialUrl,
      'url': instance.url,
    };

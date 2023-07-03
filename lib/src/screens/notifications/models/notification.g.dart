// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Notification _$NotificationFromJson(Map<String, dynamic> json) => Notification(
      title: json['title'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$NotificationToJson(Notification instance) => <String, dynamic>{
      'title': instance.title,
      'message': instance.message,
    };

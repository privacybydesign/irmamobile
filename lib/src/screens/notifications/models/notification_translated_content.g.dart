// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_translated_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InternalTranslatedContent _$InternalTranslatedContentFromJson(Map<String, dynamic> json) => InternalTranslatedContent(
  titleTranslationKey: json['titleTranslationKey'] as String,
  messageTranslationKey: json['messageTranslationKey'] as String,
);

Map<String, dynamic> _$InternalTranslatedContentToJson(InternalTranslatedContent instance) => <String, dynamic>{
  'titleTranslationKey': instance.titleTranslationKey,
  'messageTranslationKey': instance.messageTranslationKey,
};

ExternalTranslatedContent _$ExternalTranslatedContentFromJson(Map<String, dynamic> json) => ExternalTranslatedContent(
  translatedTitle: TranslatedValue.fromJson(json['translatedTitle'] as Map<String, dynamic>?),
  translatedMessage: TranslatedValue.fromJson(json['translatedMessage'] as Map<String, dynamic>?),
);

Map<String, dynamic> _$ExternalTranslatedContentToJson(ExternalTranslatedContent instance) => <String, dynamic>{
  'translatedTitle': instance.translatedTitle,
  'translatedMessage': instance.translatedMessage,
};

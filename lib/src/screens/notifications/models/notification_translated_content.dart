import 'package:json_annotation/json_annotation.dart';

import '../../../models/translated_value.dart';

part 'notification_translated_content.g.dart';

abstract class NotificationTranslatedContent {
  Map<String, dynamic> toJson();

  NotificationTranslatedContent();

  // Implement a factory method to create the correct notification type based on the JSON
  factory NotificationTranslatedContent.fromJson(Map<String, dynamic> json) {
    if (json['translationType'] == 'internalTranslatedContent') {
      return InternalTranslatedContent.fromJson(json);
    } else if (json['translationType'] == 'externalTranslatedContent') {
      return ExternalTranslatedContent.fromJson(json);
    }
    throw Exception('Cannot create notification from this JSON');
  }
}

@JsonSerializable()
class InternalTranslatedContent extends NotificationTranslatedContent {
  final String titleTranslationKey;
  final String messageTranslationKey;

  InternalTranslatedContent({
    required this.titleTranslationKey,
    required this.messageTranslationKey,
  });

  @override
  Map<String, dynamic> toJson() {
    final jsonMap = _$InternalTranslatedContentToJson(this);
    jsonMap['translationType'] = 'internalTranslatedContent';

    return jsonMap;
  }

  factory InternalTranslatedContent.fromJson(Map<String, dynamic> json) => _$InternalTranslatedContentFromJson(json);
}

@JsonSerializable()
class ExternalTranslatedContent extends NotificationTranslatedContent {
  final TranslatedValue translatedTitle;
  final TranslatedValue translatedMessage;

  ExternalTranslatedContent({
    required this.translatedTitle,
    required this.translatedMessage,
  });

  @override
  Map<String, dynamic> toJson() {
    final jsonMap = _$ExternalTranslatedContentToJson(this);
    jsonMap['translationType'] = 'externalTranslatedContent';

    return jsonMap;
  }

  factory ExternalTranslatedContent.fromJson(Map<String, dynamic> json) => _$ExternalTranslatedContentFromJson(json);
}

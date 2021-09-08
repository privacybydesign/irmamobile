// This file is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

String translationMissing = '[translation missing]';

String getTranslation(BuildContext context, Map<String, String> translations) {
  if (translations.isEmpty) {
    return translationMissing;
  }

  final String translation = translations[FlutterI18n.currentLocale(context).languageCode];
  if (translation == null) {
    return translationMissing;
  }
  return translation;
}

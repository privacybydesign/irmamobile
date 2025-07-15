import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../models/translated_value.dart';

String getTranslation(BuildContext context, TranslatedValue translations) =>
    translations.translate(FlutterI18n.currentLocale(context)!.languageCode);

// Extension to get the localized language name
extension LanguageName on Locale {
  String languageName() {
    switch (languageCode) {
      case 'nl':
        return 'Nederlands';

      case 'en':
        return 'English';
    }

    throw UnsupportedError('''
      No language name found for: '$languageCode'.
      Please add the language name to the languageName() extension.
    ''');
  }
}

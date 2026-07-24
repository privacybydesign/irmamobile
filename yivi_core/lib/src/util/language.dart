import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../models/translated_value.dart";

String getTranslation(BuildContext context, TranslatedValue translations) =>
    translations.translate(FlutterI18n.currentLocale(context)!.languageCode);

/// The effective app language: the in-app language override (the
/// preferred-language preference) when set, otherwise the device's system
/// language. Returned as a bare language code ("nl"). This is the single
/// value the app pushes to the Go client; see CONTEXT.md.
String effectiveAppLanguage({
  required String preferredLanguageCode,
  required Locale systemLocale,
}) => preferredLanguageCode.isNotEmpty
    ? preferredLanguageCode
    : systemLocale.languageCode;

// Extension to get the localized language name
extension LanguageName on Locale {
  String languageName() {
    switch (languageCode) {
      case "nl":
        return "Nederlands";

      case "en":
        return "English";

      case "de":
        return "Deutsch";
    }

    throw UnsupportedError("""
      No language name found for: '$languageCode'.
      Please add the language name to the languageName() extension.
    """);
  }
}

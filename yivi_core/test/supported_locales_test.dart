import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/app.dart";
import "package:yivi_core/src/util/language.dart";

void main() {
  final supportedLocales = AppState.defaultSupportedLocales();

  test("French is a supported locale", () {
    expect(
      supportedLocales.map((locale) => locale.languageCode),
      contains("fr"),
    );
  });

  test("French is listed in its own language", () {
    final french = supportedLocales.firstWhere(
      (locale) => locale.languageCode == "fr",
    );
    expect(french.languageName(), "Français");
  });

  test("every supported locale has a language name and a locale file", () {
    for (final locale in supportedLocales) {
      expect(locale.languageName, returnsNormally);
      expect(
        File("assets/locales/${locale.languageCode}.json").existsSync(),
        isTrue,
        reason: "no locale file for ${locale.languageCode}",
      );
    }
  });
}

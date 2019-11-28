String translationMissing = '[translation missing]';
String getTranslation(Map<String, String> translations) {
  if (translations.isEmpty) {
    return translationMissing;
  }

  final String translation = translations['nl'];
  if (translation == null) {
    return translationMissing;
  }
  return translation;
}

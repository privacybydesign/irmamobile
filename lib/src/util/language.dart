String translationMissing = '[translation missing]';

@Deprecated('Implement a proper getTranslation function that respects the user\'s locale')
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

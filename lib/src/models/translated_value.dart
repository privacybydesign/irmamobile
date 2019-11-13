import 'dart:collection';

// TranslatedValue contains translated values for attributes, etc.
class TranslatedValue extends UnmodifiableMapView<String, String> {
  TranslatedValue(Map<String, String> map) : super(map);

  // translate returns the translated value for given language. If the requested
  // translation is not available, this function falls back to the lang
  // specified in `fallbackLang`. Set `fallbackLang` to `null` to disable this
  // behavior.
  //
  // TODO: use the Flutter i18n stack or BuildContext to obtain the value for
  // `lang`, so that it can be ignored as argument and this becomes a simpler
  // function.
  String translate(String lang, {String fallbackLang = 'nl'}) {
    if (containsKey(lang)) {
      return this[lang];
    }
    if (fallbackLang != null && containsKey(fallbackLang)) {
      return this[fallbackLang];
    }
    return null;
  }
}

import 'package:collection/collection.dart';

/// TranslatedValue contains translated values for attributes, etc.
class TranslatedValue {
  // TODO: Why is the fallback language nl?
  static const _defaultFallbackLang = 'nl';

  final Map<String, String> _map;

  // We need constant constructors such that we can use hardcoded default values.
  const TranslatedValue(this._map);
  const TranslatedValue.empty() : _map = const {};

  factory TranslatedValue.fromString(String text) => TranslatedValue({_defaultFallbackLang: text});

  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;

  Iterable<String> get values => _map.values;

  bool hasTranslation(String lang) => _map.containsKey(lang);

  /// translate returns the translated value for given language. If the requested
  /// translation is not available, this function falls back to the lang
  /// specified in `fallbackLang`. Set `fallbackLang` to `null` to disable this
  /// behavior. If there is also no translation for the fallback language, then
  /// the fallback string is returned.
  ///
  /// TODO: use the Flutter i18n stack or BuildContext to obtain the value for
  /// `lang`, so that it can be ignored as argument and this becomes a simpler
  /// function.
  String translate(
    String lang, {
    String fallbackLang = _defaultFallbackLang,
    String fallback = '[translation missing]',
  }) {
    if (_map.containsKey(lang)) {
      return _map[lang]!;
    }
    if (_map.containsKey(fallbackLang)) {
      return _map[fallbackLang]!;
    }
    if (_map.containsKey(_defaultFallbackLang)) {
      return _map[_defaultFallbackLang]!;
    }
    return fallback;
  }

  // We inconsistently marshal empty TranslatedValue instances with null or with an empty map.
  // We manually correct this inconsistency here. This is not needed anymore when we start
  // using json_serializable >= 5.0.0. Then, the fallback value of the default constructor of the model will be used.
  // For this, we first have to upgrade to Flutter >= 2.5.0.
  factory TranslatedValue.fromJson(Map<String, dynamic>? json) =>
      json == null ? const TranslatedValue.empty() : TranslatedValue(Map<String, String>.from(json));
  Map<String, dynamic> toJson() => UnmodifiableMapView(_map);
}

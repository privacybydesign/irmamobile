import "dart:convert";
import "dart:io";

import "package:flutter_test/flutter_test.dart";

/// Recursively flattens a nested translation map into dot-separated keys,
/// e.g. {"pin": {"unlock": "..."}} -> {"pin.unlock"}.
Set<String> _flattenKeys(Map<String, dynamic> map, [String prefix = ""]) {
  final keys = <String>{};
  map.forEach((key, value) {
    final fullKey = prefix.isEmpty ? key : "$prefix.$key";
    if (value is Map<String, dynamic>) {
      keys.addAll(_flattenKeys(value, fullKey));
    } else {
      keys.add(fullKey);
    }
  });
  return keys;
}

Map<String, dynamic> _loadLocale(String locale) {
  final file = File("assets/locales/$locale.json");
  return json.decode(file.readAsStringSync()) as Map<String, dynamic>;
}

Set<String> _loadKeys(String locale) => _flattenKeys(_loadLocale(locale));

/// Flattens a nested translation map into dot-separated key -> string pairs.
Map<String, String> _flattenValues(
  Map<String, dynamic> map, [
  String prefix = "",
]) {
  final values = <String, String>{};
  map.forEach((key, value) {
    final fullKey = prefix.isEmpty ? key : "$prefix.$key";
    if (value is Map<String, dynamic>) {
      values.addAll(_flattenValues(value, fullKey));
    } else {
      values[fullKey] = value as String;
    }
  });
  return values;
}

final _placeholder = RegExp(r"\{[A-Za-z_]+\}");

List<String> _placeholders(String text) =>
    _placeholder.allMatches(text).map((m) => m.group(0)!).toList()..sort();

void main() {
  // English is the reference locale: every other locale must define the same keys.
  const referenceLocale = "en";
  const otherLocales = ["de", "fr", "nl"];

  final referenceKeys = _loadKeys(referenceLocale);
  final referenceValues = _flattenValues(_loadLocale(referenceLocale));

  for (final locale in otherLocales) {
    test("$locale.json has the same keys as $referenceLocale.json", () {
      final localeKeys = _loadKeys(locale);

      final missing = referenceKeys.difference(localeKeys).toList()..sort();
      final extra = localeKeys.difference(referenceKeys).toList()..sort();

      expect(
        missing,
        isEmpty,
        reason:
            "$locale.json is missing keys present in $referenceLocale.json: $missing",
      );
      expect(
        extra,
        isEmpty,
        reason:
            "$locale.json has keys not present in $referenceLocale.json: $extra",
      );
    });
  }

  for (final locale in otherLocales) {
    test("$locale.json uses the same placeholders as $referenceLocale.json", () {
      final localeValues = _flattenValues(_loadLocale(locale));

      final mismatched = <String>[
        for (final entry in referenceValues.entries)
          if (localeValues.containsKey(entry.key) &&
              _placeholders(entry.value).join() !=
                  _placeholders(localeValues[entry.key]!).join())
            entry.key,
      ]..sort();

      expect(
        mismatched,
        isEmpty,
        reason:
            "$locale.json has other placeholders than $referenceLocale.json for: $mismatched",
      );
    });
  }
}

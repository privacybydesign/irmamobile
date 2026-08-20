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

Set<String> _loadKeys(String locale) {
  final file = File("assets/locales/$locale.json");
  final content = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  return _flattenKeys(content);
}

void main() {
  // English is the reference locale: every other locale must define the same keys.
  const referenceLocale = "en";
  const otherLocales = ["de", "nl"];

  final referenceKeys = _loadKeys(referenceLocale);

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
}

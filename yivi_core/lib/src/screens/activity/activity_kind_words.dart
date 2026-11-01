import "../../models/log_entry.dart";
import "../../providers/credentials_search.dart";

/// The words of typed search that say what happened ("gedeeld", "gedeeld
/// met", "ontvangen van") read as the kind of entry to find, and the other
/// words left to search for: "BSN gedeeld met almere" asks for shared
/// entries with "BSN almere".
///
/// [phrases] are each kind's ways of saying it, in the app's language: its
/// label and its relation ("Gedeeld", "Gedeeld met"). The longest phrase
/// that matches at a place wins; matching ignores case and accents.
(Set<LogType> kinds, String rest) readKindWords(
  String typed,
  Map<LogType, List<String>> phrases,
) {
  List<String> words(String s) =>
      s.trim().split(RegExp(r"\s+")).where((w) => w.isNotEmpty).toList();
  final tokens = words(typed);
  final normal = [for (final t in tokens) normaliseForSearch(t)];
  // Longest first, so "gedeeld met" goes before "gedeeld".
  final candidates = [
    for (final MapEntry(key: kind, value: list) in phrases.entries)
      for (final phrase in list)
        (kind, [for (final w in words(phrase)) normaliseForSearch(w)]),
  ]..sort((a, b) => b.$2.length.compareTo(a.$2.length));

  final kinds = <LogType>{};
  final rest = <String>[];
  var i = 0;
  while (i < tokens.length) {
    final match = candidates.where((c) {
      final p = c.$2;
      if (p.isEmpty || i + p.length > tokens.length) return false;
      for (var j = 0; j < p.length; j++) {
        if (normal[i + j] != p[j]) return false;
      }
      return true;
    }).firstOrNull;
    if (match == null) {
      rest.add(tokens[i]);
      i++;
    } else {
      kinds.add(match.$1);
      i += match.$2.length;
    }
  }
  return (kinds, rest.join(" "));
}

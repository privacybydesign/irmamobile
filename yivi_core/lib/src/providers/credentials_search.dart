import "package:collection/collection.dart";

/// A single candidate the search algorithm scores against.
///
/// [credentialType] and [issuerName] are expected to be pre-normalised via
/// [normaliseForSearch] — lowercased, hyphen-stripped, with Latin-1 diacritics
/// folded to their ASCII form. [hash] is opaque to the algorithm and is used
/// by callers to look the candidate back up after the search.
class SearchEntry {
  final String hash;
  final String credentialType;
  final String issuerName;

  const SearchEntry({
    required this.hash,
    required this.credentialType,
    required this.issuerName,
  });
}

/// Normalise text for searching: lowercase, fold common Latin-1 diacritics
/// to ASCII (`café` → `cafe`), strip hyphens, trim. Apply to both query
/// and target so accented credential names match unaccented user input.
String normaliseForSearch(String s) {
  final lower = s.toLowerCase().trim().replaceAll("-", "");
  if (!_hasDiacritic(lower)) return lower;
  final sb = StringBuffer();
  for (final code in lower.codeUnits) {
    sb.write(_folded[code] ?? String.fromCharCode(code));
  }
  return sb.toString();
}

/// Filter and sort [candidates] by relevance to [query]. Best matches first.
/// Candidates below the 0.25 relevance floor are dropped.
List<SearchEntry> searchCredentials(
  List<SearchEntry> candidates,
  String query,
) {
  final normalised = normaliseForSearch(query);

  return candidates
      .map((c) => MapEntry(c, scoreSearchEntry(c, normalised)))
      // Floor sits at 0.25 — high enough to filter low-confidence fuzzy hits
      // (`yvi` ↔ `yivi` weighted to 0.21) but low enough that an issuer-only
      // substring match (0.9 × 0.3 = 0.27) still surfaces.
      .where((e) => e.value >= 0.25)
      .sorted((a, b) => b.value.compareTo(a.value))
      .map((e) => e.key)
      .toList(growable: false);
}

/// Score [entry] against [query] (already normalised). Combines credential
/// type and issuer name with 0.7 / 0.3 weighting.
double scoreSearchEntry(SearchEntry entry, String query) {
  final credentialScore = maxTokenScore(query, entry.credentialType);
  final issuerScore = maxTokenScore(query, entry.issuerName);
  return credentialScore * 0.7 + issuerScore * 0.3;
}

/// Score [query] against [target] and return the best per-token match.
///
/// Per-token avoids bigram pile-up across word boundaries. Joined-prefix
/// covers queries typed with adjacent words run together (`jegem` →
/// `Je Gemeente`). Joined-contains is deliberately not done — too permissive.
///
/// Fuzzy fallback is Damerau-Levenshtein distance: up to 2 edits is treated
/// as a match (1 → 0.9, 2 → 0.7), beyond that no fuzzy contribution.
double maxTokenScore(String query, String target) {
  if (target.replaceAll(" ", "").startsWith(query)) return 1;

  double best = 0;
  for (final token in target.split(" ")) {
    if (token.isEmpty) continue;
    if (token.startsWith(query)) return 1;
    if (token.contains(query)) {
      if (0.9 > best) best = 0.9;
      continue;
    }
    final fuzzy = _fuzzyScore(query, token);
    if (fuzzy > best) best = fuzzy;
  }
  return best;
}

double _fuzzyScore(String query, String token) {
  // Cheap early-out: if lengths differ by more than 2 the distance is too.
  if ((query.length - token.length).abs() > 2) return 0;
  final dist = _damerauLevenshtein(query, token);
  if (dist > 2) return 0;
  // dist 0 → 1.0, 1 → 0.9, 2 → 0.7. Issuer-only 1-edit (weighted 0.27)
  // still passes the 0.25 floor; issuer-only 2-edit (0.21) doesn't.
  return [1.0, 0.9, 0.7][dist];
}

/// Damerau-Levenshtein distance between [a] and [b] — number of single-char
/// insertions, deletions, substitutions, or adjacent-character transpositions
/// needed to turn one into the other.
int _damerauLevenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  final m = a.length;
  final n = b.length;
  final d = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
  for (var i = 0; i <= m; i++) {
    d[i][0] = i;
  }
  for (var j = 0; j <= n; j++) {
    d[0][j] = j;
  }

  for (var i = 1; i <= m; i++) {
    for (var j = 1; j <= n; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      var min = d[i - 1][j - 1] + cost;
      if (d[i - 1][j] + 1 < min) min = d[i - 1][j] + 1;
      if (d[i][j - 1] + 1 < min) min = d[i][j - 1] + 1;
      if (i > 1 &&
          j > 1 &&
          a.codeUnitAt(i - 1) == b.codeUnitAt(j - 2) &&
          a.codeUnitAt(i - 2) == b.codeUnitAt(j - 1) &&
          d[i - 2][j - 2] + 1 < min) {
        min = d[i - 2][j - 2] + 1;
      }
      d[i][j] = min;
    }
  }
  return d[m][n];
}

bool _hasDiacritic(String s) {
  for (final code in s.codeUnits) {
    if (_folded.containsKey(code)) return true;
  }
  return false;
}

// Latin-1 supplement + a few extras (œ, ß). Covers Dutch/German/French
// diacritics typical of European credential names. Multi-byte chars (e.g.
// curly quotes) are left alone.
const Map<int, String> _folded = {
  0x00e0: "a", 0x00e1: "a", 0x00e2: "a", 0x00e3: "a", 0x00e4: "a",
  0x00e5: "a", 0x00e6: "ae", 0x00e7: "c",
  0x00e8: "e", 0x00e9: "e", 0x00ea: "e", 0x00eb: "e",
  0x00ec: "i", 0x00ed: "i", 0x00ee: "i", 0x00ef: "i",
  0x00f0: "d", 0x00f1: "n",
  0x00f2: "o", 0x00f3: "o", 0x00f4: "o", 0x00f5: "o", 0x00f6: "o",
  0x00f8: "o",
  0x00f9: "u", 0x00fa: "u", 0x00fb: "u", 0x00fc: "u",
  0x00fd: "y", 0x00ff: "y", 0x00fe: "th",
  0x00df: "ss",
  0x0153: "oe", 0x0152: "oe",
};

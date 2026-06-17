import "package:collection/collection.dart";
import "package:string_similarity/string_similarity.dart";

/// A single candidate the search algorithm scores against.
///
/// [credentialType] and [issuerName] are expected to be pre-normalised
/// (lowercased, hyphen-stripped). [hash] is opaque to the algorithm and is
/// used by callers to look the candidate back up after the search.
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

/// Filter and sort [candidates] by relevance to [query]. Best matches first.
///
/// The query is lowercased, trimmed, and stripped of hyphens before matching.
/// Candidates below the relevance floor (0.3) are dropped.
List<SearchEntry> searchCredentials(
  List<SearchEntry> candidates,
  String query,
) {
  final strippedQuery = query.toLowerCase().trim().replaceAll("-", "");

  return candidates
      .map((c) => MapEntry(c, scoreSearchEntry(c, strippedQuery)))
      // Floor raised from 0.2 to 0.3 alongside tokenisation. Bigram similarity
      // between unrelated words like "overheid" ↔ "verified" lands around 0.29
      // (shared "ve"/"er"); 0.3 cuts those off while keeping realistic typos
      // (e.g. "paspot" ↔ "paspoort" ≈ 0.67).
      .where((e) => e.value >= 0.3)
      .sorted((a, b) => b.value.compareTo(a.value))
      .map((e) => e.key)
      .toList(growable: false);
}

/// Score a single [entry] against [query]. Returns a value in `[0, 1]` where
/// higher means more relevant. Combines the credential type and issuer name
/// scores with a 0.7 / 0.3 weighting.
double scoreSearchEntry(SearchEntry entry, String query) {
  final credentialScore = maxTokenScore(query, entry.credentialType);
  final issuerScore = maxTokenScore(query, entry.issuerName);
  return credentialScore * 0.7 + issuerScore * 0.3;
}

/// Score [query] against [target] and return the best match.
///
/// Per-token rather than whole-string because Dice's coefficient over a long
/// string accumulates incidental shared bigrams (e.g. "overheid" picks up
/// "ve"/"er" from "verified email" through a meaningless overlap). The
/// joined-prefix shortcut catches users typing adjacent words together
/// (e.g. "jegem" → "Je Gemeente"); joined-contains would be too permissive.
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
    final fuzzy = query.similarityTo(token);
    if (fuzzy > best) best = fuzzy;
  }
  return best;
}

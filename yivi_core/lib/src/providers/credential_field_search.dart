import "credentials_search.dart";

/// One field of a card, as the search sees it: its label and its value as
/// the app shows them. [value] is null for what is never searched (yes/no
/// values and images).
class SearchField {
  /// The field's claim path key (`claimPathKey`), to find it back in the card.
  final String claimKey;
  final String label;
  final String? value;

  const SearchField({required this.claimKey, required this.label, this.value});
}

/// Where a match is, in the text as shown (not the folded text).
class SearchMatch {
  final int start;
  final int end;

  const SearchMatch(this.start, this.end);

  @override
  bool operator ==(Object other) =>
      other is SearchMatch && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => "SearchMatch($start, $end)";
}

enum FieldHitKind { label, value }

/// A field that matched the query: through its label or through its value.
class FieldHit {
  final SearchField field;
  final FieldHitKind kind;

  /// The matched part of the label ([FieldHitKind.label]) or of the value.
  final SearchMatch match;

  const FieldHit({
    required this.field,
    required this.kind,
    required this.match,
  });
}

/// A card in the search results. [byName] when its name, hint or issuer
/// matched; [hits] are the fields that matched, in the card's order.
class CardSearchResult {
  final String hash;
  final bool byName;
  final List<FieldHit> hits;

  const CardSearchResult({
    required this.hash,
    required this.byName,
    required this.hits,
  });
}

/// Labels are searched from this many characters on, values from
/// [minValueQuery]: shorter queries hit a field on nearly every card.
const minLabelQuery = 2;
const minValueQuery = 3;

/// The fields of [fields] that [query] matches. Stricter than the name
/// search: only at the start of a word, no typos, so "adres" does not find
/// "E-mailadres" and "anna" does not find "Hanna". A label match wins over a
/// value match on the same field.
List<FieldHit> matchFields(List<SearchField> fields, String query) {
  final q = _fold(query.trim()).text;
  if (q.length < minLabelQuery) return const [];
  final hits = <FieldHit>[];
  for (final f in fields) {
    final label = findWordPrefix(f.label, q, ignoreHyphens: true);
    if (label != null) {
      hits.add(FieldHit(field: f, kind: FieldHitKind.label, match: label));
      continue;
    }
    final value = f.value;
    if (value == null || q.length < minValueQuery) continue;
    final found = findWordPrefix(value, q);
    if (found != null) {
      hits.add(FieldHit(field: f, kind: FieldHitKind.value, match: found));
    }
  }
  return hits;
}

/// The search results in the order they show:
/// 1. the cards the name search found ([byName], already best first);
/// 2. cards found through a field label;
/// 3. cards found through a field value.
/// Within 2 and 3 the cards keep their place in [order].
List<CardSearchResult> rankCards({
  required List<String> order,
  required List<String> byName,
  required Map<String, List<SearchField>> fields,
  required String query,
}) {
  final named = byName.toSet();
  final hitsOf = {
    for (final hash in order)
      hash: matchFields(fields[hash] ?? const [], query),
  };
  CardSearchResult result(String hash, {required bool name}) =>
      CardSearchResult(hash: hash, byName: name, hits: hitsOf[hash]!);
  final rest = order.where((h) => !named.contains(h) && hitsOf[h]!.isNotEmpty);
  bool byLabel(String h) =>
      hitsOf[h]!.any((hit) => hit.kind == FieldHitKind.label);
  return [
    for (final h in byName)
      if (hitsOf.containsKey(h)) result(h, name: true),
    for (final h in rest.where(byLabel)) result(h, name: false),
    for (final h in rest.where((h) => !byLabel(h))) result(h, name: false),
  ];
}

/// Where [query] (already folded, see [foldQuery]) starts a word in [text].
/// A word starts at the beginning or after anything that is not a letter or
/// digit. With [ignoreHyphens], when nothing matched, hyphens are dropped on
/// both sides and the whole text is the match ("email" in "E-mailadres").
SearchMatch? findWordPrefix(
  String text,
  String query, {
  bool ignoreHyphens = false,
}) {
  if (query.isEmpty) return null;
  final folded = _fold(text);
  final t = folded.text;
  for (var i = 0; i + query.length <= t.length; i++) {
    final wordStart = i == 0 || !_isWordChar(t.codeUnitAt(i - 1));
    if (wordStart && t.startsWith(query, i)) {
      return folded.original(i, i + query.length);
    }
  }
  if (!ignoreHyphens) return null;
  final q = query.replaceAll("-", "");
  if (q.isEmpty) return null;
  final words = t.replaceAll("-", "").split(_nonWord);
  return words.any((w) => w.startsWith(q)) ? SearchMatch(0, text.length) : null;
}

/// Where [query] (already folded) shows up anywhere in [text]: the name
/// search also finds words from their middle.
SearchMatch? findAnywhere(String text, String query) {
  if (query.isEmpty) return null;
  final folded = _fold(text);
  final i = folded.text.indexOf(query);
  return i < 0 ? null : folded.original(i, i + query.length);
}

/// [query] folded the way the field search compares it: lowercase, without
/// diacritics, trimmed; hyphens kept.
String foldQuery(String query) => _fold(query.trim()).text;

final _nonWord = RegExp(r"[^\p{L}\p{N}]+", unicode: true);
final _wordChar = RegExp(r"[\p{L}\p{N}]", unicode: true);

bool _isWordChar(int codeUnit) =>
    _wordChar.hasMatch(String.fromCharCode(codeUnit));

/// [text] folded, with for each folded code unit the original character it
/// came from, so a match in the folded text can be marked in the original.
class _Folded {
  final String text;
  final List<int> from;
  final List<int> to;

  _Folded(this.text, this.from, this.to);

  SearchMatch original(int start, int end) =>
      SearchMatch(from[start], to[end - 1]);
}

_Folded _fold(String text) {
  final sb = StringBuffer();
  final from = <int>[];
  final to = <int>[];
  var i = 0;
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    final lower = char.toLowerCase();
    final folded = lower.length == 1
        ? foldCharacter(lower.codeUnitAt(0))
        : lower;
    sb.write(folded);
    for (var k = 0; k < folded.length; k++) {
      from.add(i);
      to.add(i + char.length);
    }
    i += char.length;
  }
  return _Folded(sb.toString(), from, to);
}

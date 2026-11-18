import "package:material_ui/material_ui.dart";

import "../../data/activity_log_client.dart";
import "../../models/activity_query.dart";
import "../../models/log_entry.dart";
import "../../providers/activity_providers.dart";
import "../../providers/credentials_search.dart";
import "../../util/i18n.dart";
import "activity_entry.dart";
import "activity_query_labels.dart";

/// Something to ask about the log, with the question it makes. Labels and
/// pictures are the widgets' job.
sealed class ActivityOption {
  final ActivityQuery query;

  const ActivityOption(this.query);

  /// "kind:shared", "card:…", "party:…": what the counts are kept by.
  String get key;
}

final class KindOption extends ActivityOption {
  final ActivityKind kind;
  const KindOption(this.kind, super.query);
  @override
  String get key => "kind:${kind.name}";
}

final class CardOption extends ActivityOption {
  final ActivityCardRef card;
  const CardOption(this.card, super.query);
  @override
  String get key => "card:${card.key}";
}

/// A field of a card. In the tab's suggestions the key names the card too
/// ([withCard]): while typing they come from every card.
final class FieldOption extends ActivityOption {
  final ActivityCardRef card;
  final ClaimToken token;
  final bool withCard;
  const FieldOption(this.card, this.token, super.query, {this.withCard = true});
  @override
  String get key =>
      withCard ? "field:${card.key}:${token.key}" : "field:${token.key}";
}

final class PartyOption extends ActivityOption {
  final PartySummary party;
  const PartyOption(this.party, super.query);
  @override
  String get key => "party:${party.key}";
}

final class PeriodOption extends ActivityOption {
  final ActivityPeriod period;
  const PeriodOption(this.period, super.query);
  @override
  String get key => "period:${period.name}";
}

/// The typed words, to find in the data alone.
final class ValueOption extends ActivityOption {
  final String words;
  const ValueOption(this.words, super.query);
  @override
  String get key => "value";
}

/// The words the search reads, in the app's language.
class ActivityWords {
  final String Function(ActivityKind kind) kind;
  final String Function(ActivityKind kind) relation;
  final String Function(ClaimToken token) field;

  const ActivityWords({
    required this.kind,
    required this.relation,
    required this.field,
  });

  factory ActivityWords.of(BuildContext context) => ActivityWords(
    kind: (k) => context.tr(k.labelKey),
    relation: (k) => context.tr(k.relationKey),
    field: (t) => claimTokenLabel(context, t),
  );

  /// Each kind's ways of saying it: its relation ("Gedeeld met"), its label
  /// with the relation's last word ("Ondertekend voor", where the relation
  /// says more), and its label ("Gedeeld").
  Map<LogType, List<String>> kindPhrases() => {
    for (final k in ActivityKind.ordered)
      k.logType: () {
        final label = kind(k);
        final rel = relation(k);
        return [rel, "$label ${rel.split(" ").last}", label];
      }(),
  };
}

/// The tab's suggestions, by group in the order shown, before the counts
/// weed out and sort. Only what narrows [asked]: no kinds once one is
/// picked, no parties once one is, and once a card is picked its fields
/// instead of the cards. While typing, what has [typed] in its name, and
/// last the typed words to find in the data alone.
List<List<ActivityOption>> activitySuggestions({
  required ActivityQuery asked,
  required String typed,
  required List<ActivityCardRef> cards,
  required List<PartySummary> parties,
  required ActivityWords words,
}) {
  final q = asked;
  final search = normaliseForSearch(typed.trim());
  bool hit(String s) =>
      search.isEmpty || normaliseForSearch(s).contains(search);
  final card = q.card;
  // The fields of the card asked about (picked fields join: either one);
  // while typing with no card asked, those of every card that match, each
  // asking about its card too.
  final fieldCards = card != null
      ? [card]
      : search.isEmpty
      ? const <ActivityCardRef>[]
      : cards;
  final value = typed.trim();
  return [
    [
      if (q.kinds.isEmpty)
        for (final k in ActivityKind.ordered)
          if (hit(words.kind(k))) KindOption(k, q.copyWith(kinds: {k.logType})),
    ],
    [
      if (card == null)
        for (final c in cards)
          if (hit(c.name)) CardOption(c, q.withCard(c)),
    ],
    [
      if (q.party == null)
        for (final p in parties)
          if (hit(p.party.name)) PartyOption(p, q.copyWith(party: () => p)),
    ],
    [
      for (final c in fieldCards)
        if (!c.removed)
          for (final g in claimTokenGroups(c.art.attributes))
            for (final t in g.tokens)
              if (!q.fields.contains(t) && hit(words.field(t)))
                FieldOption(
                  c,
                  t,
                  card == null
                      ? q.withCard(c).copyWith(fields: [t])
                      : q.copyWith(fields: {...q.fields, t}.toList()),
                ),
    ],
    if (value.isNotEmpty) [ValueOption(value, _withValue(q, value))],
  ];
}

/// [q] with [words] to find in the data alone.
ActivityQuery _withValue(ActivityQuery q, String words) {
  final value = q.value.trim();
  return q.copyWith(value: value.isEmpty ? words : "$value $words");
}

/// The filter sheet's options, each tried in [q]: every kind, card,
/// party and period, and the fields of the card asked about.
List<ActivityOption> activityFilterOptions(
  ActivityQuery q, {
  required List<ActivityCardRef> cards,
  required List<PartySummary> parties,
}) {
  final card = q.card;
  return [
    for (final k in ActivityKind.ordered)
      KindOption(k, q.copyWith(kinds: {k.logType})),
    for (final c in cards) CardOption(c, q.withCard(c)),
    if (card != null)
      for (final g in claimTokenGroups(card.art.attributes))
        for (final t in g.tokens)
          FieldOption(card, t, q.copyWith(fields: [t]), withCard: false),
    for (final p in parties) PartyOption(p, q.copyWith(party: () => p)),
    for (final p in ActivityPeriod.values)
      PeriodOption(p, q.copyWith(period: p)),
  ];
}

/// Counts what each question would find, with one question to irmago. An
/// answer to an older ask is dropped (null), as is a failure; a count
/// irmago left out is not in the map.
class ActivityOptionCounter {
  final ActivityLogClient log;
  var _asks = 0;

  ActivityOptionCounter(this.log);

  Future<Map<String, int>?> count(Map<String, ActivityQuery> tries) async {
    final ask = ++_asks;
    final keys = tries.keys.toList();
    final counts = await countActivity(log, [for (final k in keys) tries[k]!]);
    if (counts == null || ask != _asks) return null;
    return {
      for (final (i, k) in keys.indexed)
        if (i < counts.length) k: counts[i],
    };
  }
}

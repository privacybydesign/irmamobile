import "package:collection/collection.dart";

import "../../models/log_entry.dart";
import "../../models/schemaless/schemaless_events.dart" as schemaless;

/// When, in the Activity filter: a few spans back from today, or a range of
/// the user's own.
enum ActivityPeriod {
  all,
  thisMonth,
  last3Months,
  thisYear,
  custom;

  String get labelKey => "activity.query.period.$name";
}

/// One field to filter on, as a claim path: a field, a group (everything
/// under it) or a list (any of its items). Positions in a list are null:
/// irmago matches any item.
class ClaimToken {
  final List<Object?> path;

  /// The label on its own, as under its group's heading: "Straat", or
  /// "Alles" (the key, translated where shown) for the whole group.
  final String shortLabel;

  /// The label with its group: "Adres › Straat"; a group's own token is
  /// labelled with the group's name.
  final String label;

  /// The first segment of the group the token is in; null at the top.
  final String? group;

  /// The token for everything in [group].
  final bool isGroup;

  const ClaimToken({
    required this.path,
    required this.shortLabel,
    required this.label,
    this.group,
    this.isGroup = false,
  });

  /// For comparing tokens.
  String get key => path.map((e) => e ?? "*").join("/");

  @override
  bool operator ==(Object other) => other is ClaimToken && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// The fields of one group in the picker, or the loose ones ([title] null).
class ClaimTokenGroup {
  final String? title;
  final String? group;
  final List<ClaimToken> tokens;

  const ClaimTokenGroup({this.title, this.group, required this.tokens});

  ClaimToken? get all => tokens.firstWhereOrNull((t) => t.isGroup);
}

bool _isIndex(Object? seg) => seg == null || seg is num;

/// The path with every list position as null.
List<Object?> claimPattern(List<dynamic> path) => [
  for (final seg in path) _isIndex(seg) ? null : seg,
];

/// The names of the groups of [attributes], from their header rows (an
/// attribute without a value names the claims under it).
Map<String, String> _groupNames(List<schemaless.Attribute> attributes) => {
  for (final a in attributes)
    if (a.value == null &&
        a.claimPath.length == 1 &&
        a.claimPath.first is String)
      a.claimPath.first as String: a.effectiveDisplayName,
};

String _groupName(Map<String, String> names, String group) =>
    names[group] ??
    (group.isEmpty ? group : group[0].toUpperCase() + group.substring(1));

/// What can be picked from a card with [attributes]: its loose fields and
/// lists first, then each group with its "everything" token and its fields.
List<ClaimTokenGroup> claimTokenGroups(List<schemaless.Attribute> attributes) {
  final names = _groupNames(attributes);
  final top = <ClaimToken>[];
  final groups = <String, List<ClaimToken>>{};
  for (final a in attributes) {
    if (a.value == null || a.claimPath.isEmpty) continue;
    final path = a.claimPath;
    final pattern = claimPattern(path);
    final first = path.first;
    if (path.length == 1) {
      final t = ClaimToken(
        path: pattern,
        shortLabel: a.effectiveDisplayName,
        label: a.effectiveDisplayName,
      );
      if (!top.contains(t)) top.add(t);
      continue;
    }
    if (first is! String) continue;
    if (path.length == 2 && _isIndex(path[1])) {
      // A list of values: any of them.
      final name = _groupName(names, first);
      final t = ClaimToken(path: pattern, shortLabel: name, label: name);
      if (!top.contains(t)) top.add(t);
      continue;
    }
    final name = _groupName(names, first);
    final list = groups.putIfAbsent(
      first,
      () => [
        ClaimToken(
          path: [first],
          shortLabel: "all",
          label: name,
          group: first,
          isGroup: true,
        ),
      ],
    );
    final t = ClaimToken(
      path: pattern,
      shortLabel: a.effectiveDisplayName,
      label: "$name › ${a.effectiveDisplayName}",
      group: first,
    );
    if (!list.contains(t)) list.add(t);
  }
  return [
    if (top.isNotEmpty) ClaimTokenGroup(tokens: top),
    for (final MapEntry(:key, :value) in groups.entries)
      ClaimTokenGroup(title: _groupName(names, key), group: key, tokens: value),
  ];
}

/// What was shared of a card, each field under its group: "Voornamen,
/// Adres (Straat, Huisnummer), Nationaliteiten".
String describeShared(List<schemaless.Attribute> attributes) {
  final names = _groupNames(attributes);
  final out = <Object>[];
  final groups = <String, List<String>>{};
  for (final a in attributes) {
    if (a.value == null || a.claimPath.isEmpty) continue;
    final path = a.claimPath;
    final first = path.first;
    if (path.length == 1 || first is! String) {
      out.add(a.effectiveDisplayName);
      continue;
    }
    if (!groups.containsKey(first)) {
      groups[first] = [];
      out.add(_Group(first));
    }
    final isItem = path.length == 2 && _isIndex(path[1]);
    final leaf = a.effectiveDisplayName;
    if (!isItem && !groups[first]!.contains(leaf)) groups[first]!.add(leaf);
  }
  return out
      .map((x) {
        if (x is String) return x;
        final g = (x as _Group).key;
        final leaves = groups[g]!;
        final name = _groupName(names, g);
        return leaves.isEmpty ? name : "$name (${leaves.join(", ")})";
      })
      .toSet()
      .join(", ");
}

class _Group {
  final String key;
  const _Group(this.key);
}

/// The card the activity is filtered on: one in the wallet (by its hash), or
/// a type that is no longer in it (by its credential type).
class ActivityCardRef {
  final String? hash;
  final String credentialId;

  /// What to draw it as, and its name.
  final schemaless.Credential art;

  const ActivityCardRef({
    this.hash,
    required this.credentialId,
    required this.art,
  });

  factory ActivityCardRef.of(schemaless.Credential card) => ActivityCardRef(
    hash: card.hash,
    credentialId: card.credentialId,
    art: card,
  );

  bool get removed => hash == null;
  String get name => art.name;
  String get key => hash ?? "type:$credentialId";

  @override
  bool operator ==(Object other) =>
      other is ActivityCardRef && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// A question to the activity log, as the Activity tab builds it: what
/// happened (any of [kinds]), with which card and which of its fields (any
/// of [fields]), with whom, when, and words to find.
class ActivityQuery {
  final Set<LogType> kinds;
  final ActivityCardRef? card;
  final List<ClaimToken> fields;
  final PartySummary? party;
  final ActivityPeriod period;

  /// The custom range, days inclusive.
  final DateTime? from;
  final DateTime? to;
  final String text;

  const ActivityQuery({
    this.kinds = const {},
    this.card,
    this.fields = const [],
    this.party,
    this.period = ActivityPeriod.all,
    this.from,
    this.to,
    this.text = "",
  });

  static const empty = ActivityQuery();

  ActivityQuery copyWith({
    Set<LogType>? kinds,
    ActivityCardRef? Function()? card,
    List<ClaimToken>? fields,
    PartySummary? Function()? party,
    ActivityPeriod? period,
    DateTime? Function()? from,
    DateTime? Function()? to,
    String? text,
  }) => ActivityQuery(
    kinds: kinds ?? this.kinds,
    card: card == null ? this.card : card(),
    fields: fields ?? this.fields,
    party: party == null ? this.party : party(),
    period: period ?? this.period,
    from: from == null ? this.from : from(),
    to: to == null ? this.to : to(),
    text: text ?? this.text,
  );

  /// Another card drops the fields of the one before.
  ActivityQuery withCard(ActivityCardRef? card) =>
      copyWith(card: () => card, fields: const []);

  /// How many kinds of filter are set: the number on the filter button.
  int get facetCount =>
      (kinds.isNotEmpty ? 1 : 0) +
      (card != null ? 1 : 0) +
      (fields.isNotEmpty ? 1 : 0) +
      (party != null ? 1 : 0) +
      (period != ActivityPeriod.all ? 1 : 0) +
      (text.trim().isNotEmpty ? 1 : 0);

  bool get isEmpty => facetCount == 0;

  /// The custom range is the wrong way round.
  bool get rangeWrong =>
      period == ActivityPeriod.custom &&
      from != null &&
      to != null &&
      from!.isAfter(to!);

  /// The question as irmago takes it. Spans are counted back from [now].
  LogFilter toLogFilter({DateTime? now}) {
    final today = now ?? DateTime.now();
    DateTime? start;
    DateTime? end;
    switch (period) {
      case ActivityPeriod.all:
        break;
      case ActivityPeriod.thisMonth:
        start = DateTime(today.year, today.month);
      case ActivityPeriod.last3Months:
        start = DateTime(today.year, today.month - 3, today.day);
      case ActivityPeriod.thisYear:
        start = DateTime(today.year);
      case ActivityPeriod.custom:
        final from = this.from, to = this.to;
        if (from != null) start = DateTime(from.year, from.month, from.day);
        if (to != null) end = DateTime(to.year, to.month, to.day + 1);
    }
    final card = this.card;
    final words = text.trim();
    return LogFilter(
      types: kinds.isEmpty ? null : kinds.toList(),
      credentialHash: card?.hash,
      credentialId: card != null && card.removed ? card.credentialId : null,
      claimPaths: card == null || fields.isEmpty
          ? null
          : [for (final t in fields) t.path],
      partyKey: party?.key,
      text: words.isEmpty ? null : words,
      from: start,
      to: end,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ActivityQuery &&
      const SetEquality<LogType>().equals(other.kinds, kinds) &&
      other.card == card &&
      const ListEquality<ClaimToken>().equals(other.fields, fields) &&
      other.party?.key == party?.key &&
      other.period == period &&
      other.from == from &&
      other.to == to &&
      other.text == text;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(kinds),
    card,
    Object.hashAll(fields),
    party?.key,
    period,
    from,
    to,
    text,
  );
}

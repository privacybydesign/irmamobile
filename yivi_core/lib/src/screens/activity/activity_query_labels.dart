import "package:flutter_i18n/flutter_i18n.dart";
import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart";

import "../../models/log_entry.dart";
import "../../util/i18n.dart";
import "activity_entry.dart";
import "activity_query.dart";

/// The kinds of what happened, in the order the app lists them.
const activityKindOrder = [
  ActivityKind.received,
  ActivityKind.shared,
  ActivityKind.signed,
  ActivityKind.deleted,
];

/// The log type of [kind].
LogType logTypeOf(ActivityKind kind) => switch (kind) {
  ActivityKind.shared => LogType.disclosure,
  ActivityKind.received => LogType.issuance,
  ActivityKind.signed => LogType.signature,
  ActivityKind.deleted => LogType.removal,
};

String _or(BuildContext context) =>
    " ${FlutterI18n.translate(context, "activity.query.or")} ";

/// "Gedeeld of Ondertekend".
String activityKindsLabel(BuildContext context, Set<LogType> kinds) => [
  for (final kind in activityKindOrder)
    if (kinds.contains(logTypeOf(kind)))
      FlutterI18n.translate(context, kind.labelKey),
].join(_or(context));

/// A field to filter on, with its group: "Adres › Straat", "Adres (alles)".
String claimTokenLabel(BuildContext context, ClaimToken token) => token.isGroup
    ? FlutterI18n.translate(
        context,
        "activity.query.group_all",
        translationParams: {"group": token.label},
      )
    : token.label;

/// A field under its group's heading: "Straat", or "Alles".
String claimTokenShortLabel(BuildContext context, ClaimToken token) =>
    token.isGroup
    ? FlutterI18n.translate(context, "activity.kind.all")
    : token.shortLabel;

/// "Straat of Nationaliteiten".
String activityFieldsLabel(BuildContext context, List<ClaimToken> fields) =>
    fields.map((t) => claimTokenLabel(context, t)).join(_or(context));

/// "Deze maand", or a custom range: "12 sep – 20 okt", with the year when
/// it is not this one.
String activityPeriodLabel(BuildContext context, ActivityQuery query) {
  if (query.period != ActivityPeriod.custom) {
    return FlutterI18n.translate(context, query.period.labelKey);
  }
  // The year only where it is needed: on the end when it is not this year,
  // on the start when it differs from the end's.
  final from = query.from, to = query.to;
  final thisYear = DateTime.now().year;
  String day(DateTime? d, bool withYear) => d == null
      ? "…"
      : DateFormat(withYear ? "d MMM y" : "d MMM", context.lang).format(d);
  return "${day(from, from != null && from.year != (to?.year ?? thisYear))}"
      " – ${day(to, to != null && to.year != thisYear)}";
}

/// "1 keer", "4 keer".
String activityTimes(BuildContext context, int count) =>
    FlutterI18n.plural(context, "activity.query.times", count);

/// "7 resultaten".
String activityResults(BuildContext context, int count) =>
    FlutterI18n.plural(context, "activity.query.results", count);

/// The whole question in one line, so it is clear what is asked:
/// "Gedeeld · BSN uit Demo Personal data · Afgelopen 3 maanden — 4
/// resultaten".
String activityQuerySentence(
  BuildContext context,
  ActivityQuery query,
  int? total,
) {
  final count = total == null ? "" : " — ${activityResults(context, total)}";
  if (query.isEmpty) {
    return "${FlutterI18n.translate(context, "activity.query.everything")}$count";
  }
  final card = query.card;
  return [
        if (query.kinds.isNotEmpty) activityKindsLabel(context, query.kinds),
        if (card != null && query.fields.isNotEmpty)
          "${activityFieldsLabel(context, query.fields)} · ${card.name}"
        else if (card != null)
          card.name,
        if (query.party != null) query.party!.party.name,
        if (query.period != ActivityPeriod.all)
          activityPeriodLabel(context, query),
        if (query.text.trim().isNotEmpty) quotedSearch(query.text),
      ].join(" · ") +
      count;
}

/// The words searched for, in quotes.
String quotedSearch(String text) => '"${text.trim()}"';

import "package:flutter_i18n/flutter_i18n.dart";
import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart";

import "../../models/activity_query.dart";
import "../../models/log_entry.dart";
import "../../util/i18n.dart";
import "activity_entry.dart";

String _or(BuildContext context) =>
    " ${FlutterI18n.translate(context, "activity.query.or")} ";

/// "Shared or Signed".
String activityKindsLabel(BuildContext context, Set<LogType> kinds) => [
  for (final kind in ActivityKind.ordered)
    if (kinds.contains(kind.logType))
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

/// A card with the fields asked about, as its tag and the filter sheet say
/// it: "Demo Address › Street, Number" (which card each comes from), or the
/// card's name alone.
String activityCardFieldsLabel(
  BuildContext context,
  ActivityCardRef card,
  List<ClaimToken> fields,
) => fields.isEmpty
    ? card.name
    : "${card.name} › "
          "${fields.map((t) => claimTokenLabel(context, t)).join(", ")}";

/// "This month", or a custom range: "12 Sep – 20 Oct", with the year when
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

/// "7 results".
String activityResults(BuildContext context, int count) =>
    FlutterI18n.plural(context, "activity.query.results", count);

/// The whole question in one line, so it is clear what is asked:
/// "Shared · Demo Personal data › BSN · Last 3 months — 4 results".
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
        if (card != null) activityCardFieldsLabel(context, card, query.fields),
        if (query.party != null) query.party!.party.name,
        if (query.period != ActivityPeriod.all)
          activityPeriodLabel(context, query),
        if (query.text.trim().isNotEmpty) quotedSearch(query.text),
      ].join(" · ") +
      count;
}

/// The words searched for, in quotes.
String quotedSearch(String text) => '"${text.trim()}"';

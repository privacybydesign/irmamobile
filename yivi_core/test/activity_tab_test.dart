import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/activity_query.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/providers/activity_providers.dart";
import "package:yivi_core/src/providers/wallet_cards_provider.dart";
import "package:yivi_core/src/screens/activity/activity_filter_sheet.dart";
import "package:yivi_core/src/screens/activity/activity_tab.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_card.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_query_chips.dart";
import "package:yivi_core/src/screens/home/widgets/home_tab_top.dart";
import "package:yivi_core/src/theme/yivi_palette.dart";
import "package:yivi_core/src/widgets/bars/scroll_edge.dart";
import "package:yivi_core/src/widgets/input/glass_search_field.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";

TrustedParty _party(String name) =>
    TrustedParty(id: name, name: name, url: null, parent: null, verified: true);

LogCredential _credential(String name) => LogCredential(
  credentialId: "pbdf.sidn-pbdf.$name",
  formats: const [CredentialFormat.idemix],
  name: name,
  issuer: _party("Yivi"),
  attributes: [stringAttr(name, "$name value")],
  revoked: false,
  revocationSupported: false,
);

/// [count] disclosures to "Shop n", newest first, then one signature for
/// "Gemeente": the oldest entry, three pages down.
List<LogInfo> _log(int count) {
  final start = DateTime.utc(2026, 10, 17, 12);
  return [
    for (var i = 0; i < count; i++)
      LogInfo(
        id: "d$i",
        type: LogType.disclosure,
        time: start.subtract(Duration(hours: i)),
        issuanceLog: null,
        disclosureLog: DisclosureLog(
          protocol: Protocol.irma,
          credentials: [_credential(i.isEven ? "email" : "age")],
          verifier: _party("Shop $i"),
        ),
        signedMessageLog: null,
        removalLog: null,
      ),
    LogInfo(
      id: "s",
      type: LogType.signature,
      time: start.subtract(Duration(hours: count)),
      issuanceLog: null,
      disclosureLog: null,
      signedMessageLog: SignedMessageLog(
        protocol: Protocol.irma,
        credentials: [_credential("personal")],
        verifier: _party("Gemeente"),
        message: "I agree",
      ),
      removalLog: null,
    ),
  ];
}

/// Whether [e] matches [f], as irmago would answer for these fields.
bool _matches(LogInfo e, LogFilter f) {
  if (f.types != null && !f.types!.contains(e.type)) return false;
  if (f.partyKey != null && e.requestor?.id != f.partyKey) return false;
  final text = f.text?.toLowerCase();
  if (text != null) {
    final haystack = [
      e.requestor?.name,
      ...?e.disclosureLog?.credentials.map((c) => c.name),
      ...?e.signedMessageLog?.credentials.map((c) => c.name),
      e.signedMessageLog?.message,
    ].whereType<String>().join(" ").toLowerCase();
    if (!text.split(" ").every(haystack.contains)) return false;
  }
  return true;
}

/// Answers [query] over [log] as irmago would: filtered, newest first, a
/// page at a time.
LogPage _answer(List<LogInfo> log, LogQuery query) {
  final matching = [
    for (final e in log)
      if (_matches(e, query.filter)) e,
  ];
  final start = query.cursor == null ? 0 : int.parse(query.cursor!);
  final limit = query.limit ?? 20;
  final end = (start + limit).clamp(0, matching.length);
  return LogPage(
    entries: matching.sublist(start, end),
    nextCursor: end < matching.length ? "$end" : null,
    counts: query.withCounts == true
        ? LogCounts(total: matching.length, byType: const {})
        : null,
  );
}

List<PartySummary> _parties(List<LogInfo> log) => [
  for (final e in log)
    PartySummary(
      key: e.requestor!.id,
      party: e.requestor!,
      lastTime: e.time,
      count: 1,
      byType: {e.type: 1},
    ),
];

void main() {
  late IrmaRepository repo;
  late RecordingBridge bridge;
  final log = _log(25);

  setUp(() async {
    bridge = RecordingBridge()
      ..respond = (event) => switch (event) {
        QueryLogsEvent() => LogPageEvent(
          requestId: event.requestId,
          page: _answer(log, event.query),
        ),
        ListPartiesEvent() => PartiesEvent(
          requestId: event.requestId,
          parties: _parties(log),
        ),
        CountLogsEvent() => LogCountsEvent(
          requestId: event.requestId,
          counts: [
            for (final f in event.filters)
              log.where((e) => _matches(e, f)).length,
          ],
        ),
        _ => null,
      };
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

  /// The questions the tab asked irmago for the list.
  List<LogQuery> queries() => bridge.dispatched
      .whereType<QueryLogsEvent>()
      .map((e) => e.query)
      .where((q) => q.filter.types?.contains(LogType.removal) != true)
      .toList();

  Future<void> pump(
    WidgetTester tester, {
    List<Credential> cards = const [],
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await pumpHome(
      tester,
      repo: repo,
      overrides: [walletCardsProvider.overrideWithValue(cards)],
      home: ActivityTab(),
    );
    await _settle(tester);
  }

  final field = find.descendant(
    of: find.byKey(const Key("activity_search_field")),
    matching: find.byType(EditableText),
  );

  /// A tap on the field under the large title: the search, with the field
  /// to type in up in the bar.
  Future<void> startSearch(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key("activity_search_field")));
    await _settle(tester);
  }

  testWidgets("no tags until something is asked", (tester) async {
    await pump(tester);
    expect(find.text("Shop 0"), findsOneWidget);
    expect(find.byKey(const Key("activity_chips")), findsNothing);
    expect(find.byKey(const Key("activity_filter_button")), findsOneWidget);
  });

  testWidgets(
    "a pick is a tag under the field and asks at once; the keyboard stays; "
    "Enter keeps it",
    (tester) async {
      await pump(tester);
      await startSearch(tester);
      await _settle(tester);
      expect(find.byKey(const Key("activity_suggestions")), findsOneWidget);
      expect(find.byKey(const Key("activity_search_cancel")), findsOneWidget);

      await tester.tap(
        find.byKey(const Key("activity_suggestion_kind:signed")),
      );
      await _settle(tester);
      // Still searching: the tag shows, the field keeps the keyboard, and
      // the log already shows what it finds. No kind is suggested any more:
      // a second would only widen the question.
      expect(find.byKey(const Key("activity_suggestions")), findsOneWidget);
      expect(find.byKey(const Key("activity_chip_kinds")), findsOneWidget);
      expect(tester.testTextInput.hasAnyClients, isTrue);
      expect(queries().last.filter.types, [LogType.signature]);
      final rows = find.byType(ActivityCard);
      expect(
        find.descendant(of: rows, matching: find.text("Gemeente")),
        findsOneWidget,
      );
      expect(
        find.descendant(of: rows, matching: find.text("Shop 0")),
        findsNothing,
      );
      expect(
        find.byKey(const Key("activity_suggestion_kind:signed")),
        findsNothing,
      );
      expect(
        find.byKey(const Key("activity_suggestion_kind:shared")),
        findsNothing,
      );

      await tester.testTextInput.receiveAction(TextInputAction.search);
      await _settle(tester);
      expect(find.byKey(const Key("activity_suggestions")), findsNothing);
      expect(queries().last.filter.types, [LogType.signature]);
      expect(find.byKey(const Key("activity_chip_kinds")), findsOneWidget);
      expect(find.text("Gemeente"), findsOneWidget);
      expect(find.text("Shop 0"), findsNothing);

      await tester.tap(find.byKey(const Key("activity_chip_kinds")));
      await _settle(tester);
      expect(queries().last.filter.types, isNull);
      expect(find.byKey(const Key("activity_chips")), findsNothing);
      expect(find.text("Shop 0"), findsOneWidget);
    },
  );

  testWidgets("a tag's cross while typing takes it off; the keyboard stays", (
    tester,
  ) async {
    await pump(tester);
    await startSearch(tester);
    await _settle(tester);
    await tester.tap(find.byKey(const Key("activity_suggestion_kind:signed")));
    await _settle(tester);
    await tester.tap(find.byKey(const Key("activity_chip_kinds")));
    await _settle(tester);
    expect(find.byKey(const Key("activity_suggestions")), findsOneWidget);
    expect(find.byKey(const Key("activity_chips")), findsNothing);
    expect(tester.testTextInput.hasAnyClients, isTrue);
    expect(
      find.byKey(const Key("activity_suggestion_kind:signed")),
      findsOneWidget,
    );
  });

  testWidgets("the tags pin under the bar as they scroll up to it", (
    tester,
  ) async {
    await pump(tester);
    await startSearch(tester);
    await _settle(tester);
    await tester.tap(find.byKey(const Key("activity_suggestion_kind:shared")));
    await _settle(tester);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _settle(tester);
    expect(find.byKey(const Key("activity_chips")), findsOneWidget);

    await tester.drag(find.text("Shop 3"), const Offset(0, -400));
    await _settle(tester);
    final pinTop = HomeTabTop.barHeight + HomeTabTop.belowGap;
    expect(
      find
          .byKey(const Key("activity_chips"))
          .evaluate()
          .map((e) => tester.getTopLeft(find.byWidget(e.widget)).dy),
      contains(pinTop),
    );
  });

  testWidgets("typing suggests the parties that match", (tester) async {
    await pump(tester);
    await startSearch(tester);
    await tester.enterText(field, "shop 17");
    await _settle(tester);
    await tester.tap(
      find.byKey(const Key("activity_suggestion_party:Shop 17")),
    );
    await _settle(tester);
    // The field is empty again, for the next tag.
    expect(tester.widget<EditableText>(field).controller.text, isEmpty);
    expect(find.byKey(const Key("activity_chip_party")), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _settle(tester);
    expect(queries().last.filter.partyKey, "Shop 17");
    expect(find.byType(ActivityCard), findsOneWidget);
    expect(find.byKey(const Key("activity_chip_party")), findsOneWidget);
  });

  testWidgets("a typed kind and its relation ask for that kind", (
    tester,
  ) async {
    await pump(tester);
    await startSearch(tester);
    await tester.enterText(field, "signed for gemeente");
    await _settle(tester);
    expect(queries().last.filter.types, [LogType.signature]);
    expect(queries().last.filter.text, "gemeente");
    expect(find.text("Gemeente"), findsWidgets);
    expect(find.text("Shop 0"), findsNothing);
  });

  testWidgets("the search key searches the typed words: the field stays "
      "with them, and the filter takes Cancel's place", (tester) async {
    await pump(tester);
    await startSearch(tester);
    await tester.enterText(field, "agree");
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _settle(tester);
    expect(queries().last.filter.text, "agree");
    expect(tester.widget<EditableText>(field).controller.text, "agree");
    expect(find.byKey(const Key("activity_chip_text")), findsNothing);
    expect(find.byKey(const Key("activity_search_cancel")), findsNothing);
    expect(find.byKey(const Key("activity_filter_button")), findsOneWidget);
    expect(find.byKey(const Key("activity_suggestions")), findsNothing);
    expect(find.text("Gemeente"), findsOneWidget);
    expect(find.byKey(const Key("activity_result_count")), findsOneWidget);

    // Back in the field: typing again, with Cancel.
    await tester.tap(field);
    await _settle(tester);
    expect(find.byKey(const Key("activity_search_cancel")), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _settle(tester);

    // Cleared, with no tags either: the search is over.
    await tester.tap(
      find.descendant(
        of: find.byType(GlassSearchField),
        matching: find.byIcon(Icons.close),
      ),
    );
    await _settle(tester);
    expect(queries().last.filter.text, isNull);
    expect(find.byType(GlassSearchField), findsNothing);
    expect(find.byKey(const Key("activity_filter_button")), findsOneWidget);
  });

  testWidgets("typed words can be found in the data alone", (tester) async {
    await pump(tester);
    await startSearch(tester);
    await tester.enterText(field, "gmail");
    await _settle(tester);
    await tester.tap(find.byKey(const Key("activity_suggestion_value")));
    await _settle(tester);
    expect(find.byKey(const Key("activity_chip_value")), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _settle(tester);
    expect(queries().last.filter.value, "gmail");
    expect(queries().last.filter.text, isNull);
  });

  testWidgets("searching shows the results as you type, with how many; "
      "Cancel goes back", (tester) async {
    await pump(tester);
    await startSearch(tester);
    expect(find.byKey(const Key("activity_show_results")), findsNothing);
    await tester.enterText(field, "agree");
    await _settle(tester);
    final count = log
        .where((e) => _matches(e, const LogFilter(text: "agree")))
        .length;
    expect(queries().last.filter.text, "agree");
    expect(
      tester.widget<Text>(find.byKey(const Key("activity_result_count"))).data,
      count == 1 ? "1 result" : "$count results",
    );
    expect(
      find.descendant(
        of: find.byType(ActivityCard),
        matching: find.text("Gemeente"),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key("activity_search_cancel")));
    await _settle(tester);
    expect(queries().last.filter.text, isNull);
    expect(find.text("Shop 0"), findsOneWidget);
  });

  testWidgets("suggestions only narrow, and never lead to nothing", (
    tester,
  ) async {
    await pump(tester);
    await startSearch(tester);
    // Nothing was deleted or received in this log: those are not offered.
    expect(
      find.byKey(const Key("activity_suggestion_kind:deleted")),
      findsNothing,
    );
    expect(
      find.byKey(const Key("activity_suggestion_kind:shared")),
      findsOneWidget,
    );
    await tester.enterText(field, "shop 17");
    await _settle(tester);
    await tester.tap(
      find.byKey(const Key("activity_suggestion_party:Shop 17")),
    );
    await _settle(tester);
    // A party is picked: no parties any more.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith(
              "activity_suggestion_party:",
            ),
      ),
      findsNothing,
    );
  });

  testWidgets("Cancel leaves the question as it was", (tester) async {
    await pump(tester);
    await startSearch(tester);
    await tester.enterText(field, "gem");
    await _settle(tester);
    await tester.tap(find.byKey(const Key("activity_search_cancel")));
    await _settle(tester);
    expect(find.byKey(const Key("activity_suggestions")), findsNothing);
    expect(find.text("Shop 0"), findsOneWidget);
  });

  testWidgets("a picked party missing from the list is shown with all "
      "parties, and the provider's list is left alone", (tester) async {
    final parties = _parties(log);
    final count = parties.length;
    final missing = PartySummary(
      key: "Elsewhere",
      party: parties.first.party,
      lastTime: parties.first.lastTime,
      count: 1,
      byType: const {},
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await pumpHome(
      tester,
      repo: repo,
      overrides: [
        walletCardsProvider.overrideWithValue(const []),
        activityPartiesProvider.overrideWith((ref) async => parties),
      ],
      home: Builder(
        builder: (context) => TextButton(
          key: const Key("open"),
          onPressed: () =>
              showActivityFilterSheet(context, ActivityQuery(party: missing)),
          child: const Text("open"),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key("open")));
    await tester.pump(const Duration(milliseconds: 500));
    await _settle(tester);

    await tester.ensureVisible(
      find.byKey(const Key("activity_filter_all_parties")),
    );
    await tester.tap(find.byKey(const Key("activity_filter_all_parties")));
    await _settle(tester);

    expect(tester.takeException(), isNull);
    expect(parties.length, count);
    expect(
      find.byKey(const Key("activity_filter_party_Elsewhere")),
      findsOneWidget,
    );
  });

  testWidgets(
    "the filter sheet counts as you pick and fades what no longer fits",
    (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key("activity_filter_button")));
      await tester.pump(const Duration(milliseconds: 500));
      await _settle(tester);
      expect(find.textContaining("26 results"), findsWidgets);

      // Gemeente is the oldest party: under "Show all".
      await tester.ensureVisible(
        find.byKey(const Key("activity_filter_all_parties")),
      );
      await tester.tap(find.byKey(const Key("activity_filter_all_parties")));
      await _settle(tester);
      await tester.ensureVisible(
        find.byKey(const Key("activity_filter_party_Gemeente")),
      );
      await tester.tap(find.byKey(const Key("activity_filter_party_Gemeente")));
      await _settle(tester);
      expect(find.text("Show 1 result"), findsOneWidget);
      // Nothing was shared with Gemeente, only signed: Shared fades.
      final shared = tester.widget<Opacity>(
        find
            .descendant(
              of: find.byKey(const Key("activity_filter_kind_shared")),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(shared.opacity, lessThan(1));

      await tester.tap(find.byKey(const Key("activity_filter_apply")));
      await tester.pump(const Duration(milliseconds: 500));
      await _settle(tester);
      expect(queries().last.filter.partyKey, "Gemeente");
      expect(find.byKey(const Key("activity_chip_party")), findsOneWidget);
    },
  );

  testWidgets("typing suggests a card's fields; a pick joins the card's tag, "
      "which goes as a whole", (tester) async {
    final address = testCredential(
      type: "pbdf.sidn-pbdf.address",
      hash: "address",
      name: "Address",
      attributes: [stringAttr("Postal code", "1234AB")],
    );
    await pump(tester, cards: [address]);
    await startSearch(tester);
    await tester.enterText(field, "postal");
    await _settle(tester);
    final suggestion = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith(
            "activity_suggestion_field:",
          ),
    );
    expect(suggestion, findsOneWidget);
    expect(
      find.descendant(
        of: suggestion,
        matching: find.text("Address › Postal code"),
      ),
      findsOneWidget,
    );
    await tester.tap(suggestion);
    await _settle(tester);
    final tag = find.byKey(const Key("activity_chip_card"));
    expect(tag, findsOneWidget);
    expect(
      find.descendant(of: tag, matching: find.text("Address › Postal code")),
      findsOneWidget,
    );
    expect(queries().last.filter.claimPaths, isNotEmpty);
    await tester.tap(tag);
    await _settle(tester);
    expect(tag, findsNothing);
  });

  testWidgets("a header per day; the rows under it say only the time", (
    tester,
  ) async {
    await pump(tester);
    // 2026-10-17 was a Saturday; the entries go back an hour each.
    expect(find.textContaining("Saturday 17 October"), findsOneWidget);
    final first = find.byType(ActivityCard).first;
    final at = DateTime.utc(2026, 10, 17, 12).toLocal();
    final time = DateFormat.jm("en_US").format(at);
    expect(find.descendant(of: first, matching: find.text(time)), findsOne);
    expect(
      find.descendant(of: first, matching: find.textContaining("Oct")),
      findsNothing,
    );
  });

  testWidgets("scrolled, a day's header sticks right under the bar and "
      "takes on its band", (tester) async {
    await pump(tester);
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -500),
    );
    await _settle(tester);
    final header = find.ancestor(
      of: find.textContaining("17 October"),
      matching: find.byType(DecoratedBox),
    );
    // No safe area in the test: the bar ends at its own height.
    expect(tester.getTopLeft(header.first).dy, HomeTabTop.barHeight);
    final palette = YiviPalette.of(tester.element(header.first));
    expect(
      (tester.widget<DecoratedBox>(header.first).decoration as BoxDecoration)
          .color,
      ScrollEdgeBand.fill(palette),
    );
  });

  testWidgets("a day's header takes on the band as soon as its first row "
      "goes under it", (tester) async {
    await pump(tester);
    final row = find.byKey(
      tester.widget<ActivityCard>(find.byType(ActivityCard).first).key!,
    );
    final header = find.ancestor(
      of: find.textContaining("17 October"),
      matching: find.byType(DecoratedBox),
    );
    final scroll = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(CustomScrollView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final palette = YiviPalette.of(tester.element(header.first));
    Color? color() =>
        (tester.widget<DecoratedBox>(header.first).decoration as BoxDecoration)
            .color;
    var checked = 0;
    for (var px = 0.0; px < 200; px += 2) {
      scroll.position.jumpTo(px);
      await tester.pump();
      final under =
          tester.getTopLeft(row).dy < tester.getBottomLeft(header.first).dy;
      expect(
        color(),
        under ? ScrollEdgeBand.fill(palette) : palette.background,
        reason: "at $px",
      );
      if (under) checked++;
    }
    expect(checked, greaterThan(0));
  });

  testWidgets("the filter sheet is up at once; its cards have their own page", (
    tester,
  ) async {
    final passport = testCredential(
      type: "pbdf.pbdf.passport",
      hash: "passport",
      name: "Passport",
    );
    await pump(tester, cards: [passport]);
    await tester.tap(find.byKey(const Key("activity_filter_button")));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    // Up straight away, with a spinner until it has opened.
    expect(find.byKey(const Key("activity_filter_main")), findsOneWidget);
    expect(find.byKey(const Key("activity_filter_loading")), findsOneWidget);
    expect(
      find.byKey(const Key("activity_filter_card_passport")),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 500));
    await _settle(tester);
    expect(find.byKey(const Key("activity_filter_loading")), findsNothing);
    // One row for the card, not a row per card.
    expect(find.text("Any card"), findsOneWidget);
    expect(
      find.byKey(const Key("activity_filter_card_passport")),
      findsNothing,
    );

    await tester.ensureVisible(find.byKey(const Key("activity_filter_card")));
    await tester.tap(find.byKey(const Key("activity_filter_card")));
    await tester.pump(const Duration(milliseconds: 500));
    await _settle(tester);
    expect(find.byKey(const Key("activity_filter_cards")), findsOneWidget);
    // The cards can be searched.
    await tester.enterText(
      find.byKey(const Key("activity_filter_card_search")),
      "zzz",
    );
    await tester.pump();
    expect(find.byKey(const Key("activity_filter_card_none")), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key("activity_filter_card_search")),
      "pass",
    );
    await tester.pump();
    expect(find.byKey(const Key("activity_filter_card_any")), findsNothing);
    expect(
      find.byKey(const Key("activity_filter_card_passport")),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key("activity_filter_card_passport")));
    await tester.pump(const Duration(milliseconds: 500));
    await _settle(tester);
    expect(find.byKey(const Key("activity_filter_cards")), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key("activity_filter_card")),
        matching: find.text("Passport"),
      ),
      findsOneWidget,
    );
  });

  testWidgets("swiping back from the cards page is its back button", (
    tester,
  ) async {
    final passport = testCredential(
      type: "pbdf.pbdf.passport",
      hash: "passport",
      name: "Passport",
    );
    await pump(tester, cards: [passport]);
    await tester.tap(find.byKey(const Key("activity_filter_button")));
    await tester.pump(const Duration(milliseconds: 500));
    await _settle(tester);
    Future<void> openCards() async {
      await tester.ensureVisible(find.byKey(const Key("activity_filter_card")));
      await tester.tap(find.byKey(const Key("activity_filter_card")));
      await tester.pump(const Duration(milliseconds: 500));
      await _settle(tester);
      expect(find.byKey(const Key("activity_filter_cards")), findsOneWidget);
    }

    await openCards();
    await tester.enterText(
      find.byKey(const Key("activity_filter_card_search")),
      "zzz",
    );
    await tester.pump();
    expect(find.byKey(const Key("activity_filter_card_none")), findsOneWidget);

    await tester.fling(
      find.byKey(const Key("activity_filter_cards")),
      const Offset(300, 0),
      1000,
    );
    await tester.pump(const Duration(milliseconds: 500));
    await _settle(tester);
    expect(find.byKey(const Key("activity_filter_cards")), findsNothing);

    // The search went with the page: all cards again.
    await openCards();
    expect(find.byKey(const Key("activity_filter_card_none")), findsNothing);
    expect(
      find.byKey(const Key("activity_filter_card_passport")),
      findsOneWidget,
    );
  });

  testWidgets("scrolling down loads the next page after the last", (
    tester,
  ) async {
    await pump(tester);
    expect(queries().last.cursor, isNull);

    // The next page comes in from the bridge between drags.
    for (var i = 0; i < 20 && find.text("Gemeente").evaluate().isEmpty; i++) {
      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -600),
      );
      await _settle(tester, rounds: 3);
    }
    expect(find.text("Gemeente"), findsOneWidget);
    expect(queries().map((q) => q.cursor), contains("20"));
  });

  group("search ends and comes back (phase 13 pins)", () {
    bool searching() => find.byType(GlassSearchField).evaluate().isNotEmpty;

    testWidgets("after Enter, the field's clear button with no tags ends "
        "the search", (tester) async {
      await pump(tester);
      await startSearch(tester);
      await tester.enterText(field, "agree");
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await _settle(tester);
      expect(searching(), isTrue);
      await tester.tap(
        find.descendant(
          of: find.byType(GlassSearchField),
          matching: find.byIcon(Icons.close),
        ),
      );
      await _settle(tester);
      expect(searching(), isFalse);
      expect(queries().last.filter.text, isNull);
    });

    testWidgets("after Enter, the cross on the last tag ends the search", (
      tester,
    ) async {
      await pump(tester);
      await startSearch(tester);
      await tester.tap(
        find.byKey(const Key("activity_suggestion_kind:signed")),
      );
      await _settle(tester);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await _settle(tester);
      expect(searching(), isTrue);
      await tester.tap(find.byKey(const Key("activity_chip_kinds")));
      await _settle(tester);
      expect(searching(), isFalse);
      expect(queries().last.filter.types, isNull);
    });

    testWidgets("back in the field after Enter: Cancel returns and the "
        "suggestions come back", (tester) async {
      await pump(tester);
      await startSearch(tester);
      await tester.enterText(field, "agree");
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await _settle(tester);
      expect(find.byKey(const Key("activity_search_cancel")), findsNothing);
      expect(find.byKey(const Key("activity_suggestions")), findsNothing);
      await tester.tap(field);
      await _settle(tester);
      expect(find.byKey(const Key("activity_search_cancel")), findsOneWidget);
      expect(find.byKey(const Key("activity_suggestions")), findsOneWidget);
    });

    testWidgets("Clear while searching ends the search and asks nothing", (
      tester,
    ) async {
      await pump(tester);
      await startSearch(tester);
      await tester.enterText(field, "nothing like this");
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await _settle(tester);
      expect(queries().last.filter.text, "nothing like this");
      await tester.tap(find.byKey(const Key("activity_clear_filters")));
      await _settle(tester);
      expect(searching(), isFalse);
      final last = queries().last.filter;
      expect(last.text, isNull);
      expect(last.types, isNull);
      expect(last.partyKey, isNull);
      expect(find.text("Shop 0"), findsOneWidget);
    });

    testWidgets("Cancel without a change still scrolls the log to the top", (
      tester,
    ) async {
      await pump(tester);
      await tester.drag(find.text("Shop 3"), const Offset(0, -500));
      await _settle(tester);
      final list = find.byType(CustomScrollView).first;
      double offset() => tester
          .state<ScrollableState>(
            find.descendant(of: list, matching: find.byType(Scrollable)).first,
          )
          .position
          .pixels;
      expect(offset(), greaterThan(0));
      await tester.tap(find.byKey(const Key("activity_search_button")));
      await _settle(tester);
      await tester.tap(find.byKey(const Key("activity_search_cancel")));
      await _settle(tester);
      expect(offset(), 0);
    });

    testWidgets("suggestions: at most 4 per group, 6 while typing", (
      tester,
    ) async {
      await pump(tester);
      await startSearch(tester);
      // The row is lazy: count what it holds. Nothing typed: shared and
      // signed (nothing was received or deleted), and 4 of the 26 parties.
      int shown() => tester
          .widget<ListView>(find.byKey(const Key("activity_suggestions")))
          .semanticChildCount!;
      expect(shown(), 2 + 4);
      // Typing "shop": 6 of the 25 shops, and the words to find in the data.
      await tester.enterText(field, "shop");
      await _settle(tester);
      expect(shown(), 6 + 1);
    });

    testWidgets("suggestions: an option with an unknown count stays, and "
        "they sort only once every count is in", (tester) async {
      final answer = bridge.respond!;
      List<int>? counts(int n) => null;
      var answerCounts = counts;
      bridge.respond = (event) => event is CountLogsEvent
          ? LogCountsEvent(
              requestId: event.requestId,
              counts: answerCounts(event.filters.length) ?? const [],
            )
          : answer(event);
      double x(String kind) => tester
          .getTopLeft(find.byKey(Key("activity_suggestion_kind:$kind")))
          .dx;

      // No counts at all: nothing dropped (also what nothing has), and
      // the kinds in their own order.
      await pump(tester);
      await startSearch(tester);
      // All four kinds (two of them have nothing) and 4 parties.
      expect(
        tester
            .widget<ListView>(find.byKey(const Key("activity_suggestions")))
            .semanticChildCount,
        4 + 4,
      );
      expect(x("received"), lessThan(x("shared")));

      // Every count in, each one more than the one before: most first.
      answerCounts = (n) => [for (var i = 0; i < n; i++) i + 1];
      await tester.enterText(field, "s");
      await tester.enterText(field, "");
      await _settle(tester);
      expect(x("signed"), lessThan(x("shared")));
    });

    Future<void> openFilter(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key("activity_filter_button")));
      await tester.pump(const Duration(milliseconds: 500));
      await _settle(tester);
    }

    Future<void> applyFilter(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key("activity_filter_apply")));
      await tester.pump(const Duration(milliseconds: 500));
      await _settle(tester);
    }

    testWidgets("the filter sheet applied while searching keeps the typed "
        "words in the field, not as a tag", (tester) async {
      await pump(tester);
      await startSearch(tester);
      await tester.enterText(field, "agree");
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await _settle(tester);
      await openFilter(tester);
      await tester.tap(find.byKey(const Key("activity_filter_kind_signed")));
      await _settle(tester);
      await applyFilter(tester);
      expect(searching(), isTrue);
      expect(tester.widget<EditableText>(field).controller.text, "agree");
      expect(find.byKey(const Key("activity_chip_text")), findsNothing);
      expect(find.byKey(const Key("activity_chip_kinds")), findsOneWidget);
      expect(queries().last.filter.types, [LogType.signature]);
      expect(queries().last.filter.text, "agree");
    });

    testWidgets("an emptied filter sheet with nothing typed ends the search", (
      tester,
    ) async {
      await pump(tester);
      await startSearch(tester);
      await tester.tap(
        find.byKey(const Key("activity_suggestion_kind:signed")),
      );
      await _settle(tester);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await _settle(tester);
      await openFilter(tester);
      await tester.tap(find.byKey(const Key("activity_filter_clear")));
      await _settle(tester);
      await applyFilter(tester);
      expect(searching(), isFalse);
      expect(queries().last.filter.types, isNull);
    });

    testWidgets("a row opened while searching puts the keyboard away; back, "
        "it stays down", (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await pumpRoutes(
        tester,
        repo: repo,
        initialLocation: "/home",
        routes: [
          GoRoute(
            path: "/home",
            builder: (_, _) =>
                Scaffold(resizeToAvoidBottomInset: false, body: ActivityTab()),
            routes: [
              GoRoute(
                path: "activity_details",
                builder: (context, _) => Scaffold(
                  body: TextButton(
                    key: const Key("test_details_back"),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Back"),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
      await _settle(tester);
      bool focused() => tester.widget<EditableText>(field).focusNode.hasFocus;
      await startSearch(tester);
      await tester.enterText(field, "gemeente");
      await _settle(tester);
      expect(focused(), isTrue);
      await tester.tap(
        find.descendant(
          of: find.byType(ActivityCard),
          matching: find.text("Gemeente"),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await _settle(tester);
      expect(find.byKey(const Key("test_details_back")), findsOneWidget);
      await tester.tap(find.byKey(const Key("test_details_back")));
      await tester.pump(const Duration(milliseconds: 500));
      await _settle(tester);
      expect(searching(), isTrue);
      expect(focused(), isFalse);
    });

    testWidgets(
      "sideways: the newest entry is in the pane until one is picked; the "
      "field row floats over the list, the tags and suggestions under it",
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(874, 402);
        tester.view.padding = const FakeViewPadding(left: 62, right: 62);
        addTearDown(tester.view.reset);
        await pumpHome(tester, repo: repo, home: ActivityTab());
        await _settle(tester);
        final pane = find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith(
                "activity_detail_pane_",
              ),
        );
        expect(pane, findsOneWidget);
        expect(
          find.descendant(of: pane, matching: find.text("Shop 0")),
          findsWidgets,
        );
        await tester.tap(
          find.descendant(
            of: find.byType(ActivityCard),
            matching: find.text("Shop 2"),
          ),
        );
        await _settle(tester);
        expect(
          find.descendant(of: pane, matching: find.text("Shop 2")),
          findsWidgets,
        );

        // Over the list, before any search.
        final fieldBox = find.byKey(const Key("activity_search_field"));
        expect(fieldBox, findsOneWidget);
        await tester.tap(fieldBox);
        await _settle(tester);
        expect(find.byKey(const Key("activity_suggestions")), findsOneWidget);
        await tester.tap(
          find.byKey(const Key("activity_suggestion_kind:signed")),
        );
        await _settle(tester);
        final fieldBottom = tester.getBottomLeft(fieldBox).dy;
        expect(
          tester.getTopLeft(find.byKey(const Key("activity_chips"))).dy,
          greaterThanOrEqualTo(fieldBottom),
        );
        expect(
          tester.getTopLeft(find.byKey(const Key("activity_suggestions"))).dy,
          greaterThanOrEqualTo(fieldBottom),
        );
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    Attribute head(List<dynamic> path, String name) =>
        Attribute(claimPath: path, displayName: name);
    Attribute leaf(List<dynamic> path, String name) => Attribute(
      claimPath: path,
      displayName: name,
      value: AttributeValue(type: AttributeType.string, string: "x"),
    );

    testWidgets("filter sheet: a field group's all lights its fields as "
        "included; one of them keeps only it; all again drops it", (
      tester,
    ) async {
      final pid = testCredential(
        type: "eu.pid",
        hash: "pid",
        name: "PID",
        attributes: [
          head(["address"], "Adres"),
          leaf(["address", "street"], "Straat"),
          leaf(["address", "locality"], "Woonplaats"),
        ],
      );
      await pump(tester, cards: [pid]);
      await openFilter(tester);
      await tester.ensureVisible(find.byKey(const Key("activity_filter_card")));
      await tester.tap(find.byKey(const Key("activity_filter_card")));
      await tester.pump(const Duration(milliseconds: 500));
      await _settle(tester);
      await tester.tap(find.byKey(const Key("activity_filter_card_pid")));
      await tester.pump(const Duration(milliseconds: 500));
      await _settle(tester);
      ActivityToggleTag tag(String key) => tester.widget<ActivityToggleTag>(
        find.byKey(Key("activity_filter_field_$key")),
      );
      Future<void> tap(String key) async {
        final f = find.byKey(Key("activity_filter_field_$key"));
        await tester.ensureVisible(f);
        await tester.tap(f);
        await _settle(tester);
      }

      await tap("address");
      expect(tag("address").selected, isTrue);
      expect(tag("address/street").included, isTrue);
      expect(tag("address/locality").included, isTrue);

      await tap("address/street");
      expect(tag("address").selected, isFalse);
      expect(tag("address/street").selected, isTrue);
      expect(tag("address/locality").included, isFalse);
      expect(tag("address/locality").selected, isFalse);

      await tap("address");
      expect(tag("address").selected, isTrue);
      expect(tag("address/street").selected, isFalse);
      expect(tag("address/street").included, isTrue);
      await tap("address");
      expect(tag("address").selected, isFalse);
      expect(tag("address/street").included, isFalse);
    });

    testWidgets("filter sheet: a custom period starts a year back up to "
        "today", (tester) async {
      await pump(tester);
      await openFilter(tester);
      final custom = find.byKey(const Key("activity_filter_period_custom"));
      await tester.ensureVisible(custom);
      await tester.tap(custom);
      await _settle(tester);
      final today = DateTime.now();
      final strings = MaterialLocalizations.of(
        tester.element(find.byKey(const Key("activity_filter_main"))),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key("activity_filter_from")),
          matching: find.text(
            strings.formatMediumDate(
              DateTime(today.year - 1, today.month, today.day),
            ),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key("activity_filter_to")),
          matching: find.text(
            strings.formatMediumDate(
              DateTime(today.year, today.month, today.day),
            ),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets("filter sheet: no results disables the button, and so does "
        "a range that ends before it starts", (tester) async {
      Future<void> openWith(ActivityQuery q) async {
        // A fresh app each time: the sheet of the last one is still up.
        await tester.pumpWidget(const SizedBox());
        await pumpHome(
          tester,
          repo: repo,
          home: Builder(
            builder: (context) => TextButton(
              key: const Key("test_open_sheet"),
              onPressed: () => showActivityFilterSheet(context, q),
              child: const Text("Open"),
            ),
          ),
        );
        await _settle(tester);
        await tester.tap(find.byKey(const Key("test_open_sheet")));
        await tester.pump(const Duration(milliseconds: 500));
        await _settle(tester);
      }

      /// "No results" on the button, and a tap on it leaves the sheet up.
      Future<void> expectDisabled() async {
        final apply = find.byKey(const Key("activity_filter_apply"));
        expect(
          find.descendant(of: apply, matching: find.text("No results")),
          findsOneWidget,
        );
        await tester.tap(apply, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 500));
        await _settle(tester);
        expect(find.byKey(const Key("activity_filter_main")), findsOneWidget);
      }

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await openWith(const ActivityQuery(text: "zzz nothing"));
      await expectDisabled();

      await openWith(
        ActivityQuery(
          period: ActivityPeriod.custom,
          from: DateTime(2026, 3, 10),
          to: DateTime(2026, 3, 1),
        ),
      );
      await expectDisabled();
    });

    testWidgets("day groups split at local midnight", (tester) async {
      final late = DateTime(2026, 3, 10, 23, 30);
      final early = DateTime(2026, 3, 11, 0, 30);
      LogInfo at(String id, DateTime time) => LogInfo(
        id: id,
        type: LogType.disclosure,
        time: time.toUtc(),
        issuanceLog: null,
        disclosureLog: DisclosureLog(
          protocol: Protocol.irma,
          credentials: [_credential("email")],
          verifier: _party("Shop $id"),
        ),
        signedMessageLog: null,
        removalLog: null,
      );
      final days = [at("b", early), at("a", late)];
      bridge.respond = (event) => switch (event) {
        QueryLogsEvent() => LogPageEvent(
          requestId: event.requestId,
          page: _answer(days, event.query),
        ),
        ListPartiesEvent() => PartiesEvent(
          requestId: event.requestId,
          parties: _parties(days),
        ),
        _ => null,
      };
      await pump(tester);
      final title = DateFormat("EEEE d MMMM", "en_US");
      expect(find.text(title.format(late)), findsOneWidget);
      expect(find.text(title.format(early)), findsOneWidget);
    });
  });
}

/// Lets the bridge answer and the list rebuild a few times. The tab was
/// built on the real clock (the locale files load there), so its timers and
/// streams run there too; the loading indicator keeps animating, so
/// pumpAndSettle would not end.
Future<void> _settle(WidgetTester tester, {int rounds = 8}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/screens/activity/activity_tab.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_card.dart";

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

  Future<void> pump(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await pumpHome(
      tester,
      repo: repo,
      overrides: [irmaRepositoryProvider.overrideWithValue(repo)],
      home: ActivityTab(),
    );
    await _settle(tester);
  }

  final field = find.descendant(
    of: find.byKey(const Key("activity_search_field")),
    matching: find.byType(EditableText),
  );

  testWidgets("no tags until something is asked", (tester) async {
    await pump(tester);
    expect(find.text("Shop 0"), findsOneWidget);
    expect(find.byKey(const Key("activity_chips")), findsNothing);
    expect(find.byKey(const Key("activity_filter_button")), findsOneWidget);
  });

  testWidgets(
    "the empty field suggests what happened; a pick is a chip with a cross",
    (tester) async {
      await pump(tester);
      await tester.tap(field);
      await _settle(tester);
      expect(find.byKey(const Key("activity_suggestions")), findsOneWidget);
      expect(find.byKey(const Key("activity_search_cancel")), findsOneWidget);

      await tester.tap(
        find.byKey(const Key("activity_suggestion_kind:signed")),
      );
      await _settle(tester);
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

  testWidgets("typing suggests the parties that match", (tester) async {
    await pump(tester);
    await tester.tap(field);
    await tester.enterText(field, "shop 17");
    await _settle(tester);
    await tester.tap(
      find.byKey(const Key("activity_suggestion_party:Shop 17")),
    );
    await _settle(tester);
    expect(queries().last.filter.partyKey, "Shop 17");
    expect(find.byType(ActivityCard), findsOneWidget);
    expect(find.byKey(const Key("activity_chip_party")), findsOneWidget);
  });

  testWidgets("the search key searches the typed words", (tester) async {
    await pump(tester);
    await tester.tap(field);
    await tester.enterText(field, "agree");
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _settle(tester);
    expect(queries().last.filter.text, "agree");
    expect(find.byKey(const Key("activity_chip_text")), findsOneWidget);
    expect(find.text("Gemeente"), findsOneWidget);
    expect(find.byKey(const Key("activity_result_count")), findsOneWidget);
  });

  testWidgets("Cancel leaves the question as it was", (tester) async {
    await pump(tester);
    await tester.tap(field);
    await tester.enterText(field, "gem");
    await _settle(tester);
    await tester.tap(find.byKey(const Key("activity_search_cancel")));
    await _settle(tester);
    expect(find.byKey(const Key("activity_suggestions")), findsNothing);
    expect(find.text("Shop 0"), findsOneWidget);
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

  testWidgets("scrolling down loads the next page after the last", (
    tester,
  ) async {
    await pump(tester);
    expect(queries().last.cursor, isNull);

    // The next page comes in from the bridge between drags.
    for (var i = 0; i < 20 && find.text("Gemeente").evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -600));
      await _settle(tester, rounds: 3);
    }
    expect(find.text("Gemeente"), findsOneWidget);
    expect(queries().map((q) => q.cursor), contains("20"));
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

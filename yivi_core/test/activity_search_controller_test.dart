import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/activity_query.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/providers/activity_providers.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/wallet_cards_provider.dart";
import "package:yivi_core/src/screens/activity/activity_entry.dart";
import "package:yivi_core/src/screens/activity/activity_options.dart";
import "package:yivi_core/src/screens/activity/activity_search_controller.dart";

import "support/onboarding_v2_harness.dart";

const _words = ActivityWords(kind: _kind, relation: _relation, field: _field);
String _kind(ActivityKind k) => k.name;
String _relation(ActivityKind k) => "${k.name} with";
String _field(ClaimToken t) => t.label;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late IrmaRepository repo;
  late RecordingBridge bridge;
  late ProviderContainer container;

  setUp(() async {
    bridge = RecordingBridge()
      ..respond = (event) => switch (event) {
        QueryLogsEvent() => LogPageEvent(
          requestId: event.requestId,
          page: const LogPage(entries: [], nextCursor: null),
        ),
        ListPartiesEvent() => PartiesEvent(
          requestId: event.requestId,
          parties: const [],
        ),
        CountLogsEvent() => LogCountsEvent(
          requestId: event.requestId,
          counts: [for (final _ in event.filters) 1],
        ),
        _ => null,
      };
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
    container = ProviderContainer(
      overrides: [
        irmaRepositoryProvider.overrideWithValue(repo),
        walletCardsProvider.overrideWithValue(const []),
      ],
    );
    // Kept alive, as the tab does.
    container.listen(activitySearchProvider, (_, _) {});
  });
  tearDown(() {
    container.dispose();
    repo.close();
  });

  ActivitySearchController search() =>
      container.read(activitySearchProvider.notifier);
  ActivitySearch state() => container.read(activitySearchProvider);
  ActivityQuery asked() => container.read(activityLogProvider).filter;
  Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

  test("typing asks the log a moment after it stops, not at once", () async {
    search().start(_words);
    search().type("agree", _words);
    expect(asked().text, "");
    await wait(200);
    expect(asked().text, "agree");
  });

  test("a typed kind word asks for that kind", () async {
    search().start(_words);
    search().type("signed with gemeente", _words);
    await wait(200);
    expect(asked().kinds, {LogType.signature});
    expect(asked().text, "gemeente");
  });

  test("Cancel goes back to the question before, and to the top", () async {
    search().ask(ActivityQuery.empty.copyWith(text: "shop"));
    search().start(_words);
    search().pick(
      ActivityQuery.empty.copyWith(kinds: {LogType.disclosure}),
      _words,
    );
    final asks = state().asks;
    search().end();
    expect(state().searching, isFalse);
    expect(asked().text, "shop");
    expect(asked().kinds, isEmpty);
    expect(state().asks, asks + 1);
  });

  test("Enter with nothing asked ends the search", () {
    search().start(_words);
    search().submit("  ", _words);
    expect(state().searching, isFalse);
  });

  test("the filter sheet while searching keeps the typed words out of the "
      "draft", () async {
    search().start(_words);
    search().type("agree", _words);
    search().submit("agree", _words);
    search().applyFilter(
      ActivityQuery.empty.copyWith(kinds: {LogType.signature}, text: "x"),
      _words,
    );
    expect(state().draft!.text, "");
    expect(state().draft!.kinds, {LogType.signature});
    expect(asked().text, "agree");
  });

  test("the suggestions get their counts a moment after starting", () async {
    search().start(_words);
    expect(state().counts, isEmpty);
    await wait(250);
    expect(state().counts["kind:shared"], 1);
  });
}

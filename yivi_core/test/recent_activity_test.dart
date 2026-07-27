import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/translated_value.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_card.dart";
import "package:yivi_core/src/screens/activity/widgets/recent_activity.dart";
import "package:yivi_core/src/theme/theme.dart";

/// A bridge that answers every [LoadLogsEvent] with the most recent `max`
/// entries from [_logs], mimicking irmago. It also lets the test inject extra
/// [LogsEvent]s onto the shared event bus to model responses that belong to
/// other consumers (e.g. the Activity tab's `max: 10` load) landing while
/// Recent Activity is subscribed.
class _FakeLogsBridge extends IrmaBridge {
  final List<LogInfo> _logs;

  _FakeLogsBridge(this._logs);

  @override
  void dispatch(Event event) {
    if (event is LoadLogsEvent) {
      addEvent(LogsEvent(logEntries: _logs.take(event.max).toList()));
    }
    // AppReadyEvent and anything else is irrelevant for this test.
  }

  /// Pushes a stray [LogsEvent] onto the bridge's broadcast stream, just like
  /// irmago would when answering a different log request.
  void emitStrayLogs(List<LogInfo> logs) =>
      addEvent(LogsEvent(logEntries: logs));
}

LogInfo _log(DateTime time) => LogInfo(
  type: LogType.disclosure,
  time: time,
  issuanceLog: null,
  disclosureLog: DisclosureLog(
    protocol: Protocol.irma,
    credentials: const [],
    // A named verifier so ActivityCard can render initials in its avatar.
    verifier: TrustedParty(
      id: "verifier",
      name: TranslatedValue.fromString("Verifier"),
      url: null,
      parent: null,
      verified: true,
    ),
  ),
  signedMessageLog: null,
  removalLog: null,
);

/// Builds the test app once. [showRecentActivity] drives whether the home
/// body renders [RecentActivity]; flipping it models navigating away from and
/// back to the home tab (see HomeScreen.build, where the body switches and
/// RecentActivity is destroyed/recreated) while the shared IrmaRepository and
/// its event bus live on. The MaterialApp/i18n stay stable across the flip.
Widget _host(IrmaRepository repo, ValueListenable<bool> showRecentActivity) {
  return IrmaRepositoryProvider(
    repository: repo,
    child: IrmaTheme(
      builder: (_) => MaterialApp(
        localizationsDelegates: [
          FlutterI18nDelegate(
            translationLoader: FileTranslationLoader(
              basePath: "assets/locales",
              forcedLocale: const Locale("en", "EN"),
            ),
          ),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            child: ValueListenableBuilder<bool>(
              valueListenable: showRecentActivity,
              builder: (_, show, _) => show
                  ? RecentActivity(amountOfLogs: 2, onTap: () {})
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Mounts [widget] and lets the FileTranslationLoader finish its real-IO read
/// (the fake test clock doesn't drive rootBundle.loadString), then settles.
Future<void> _pump(WidgetTester tester, Widget widget) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(widget);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await tester.pumpAndSettle();
}

/// Drives real async so any pending bridge events / translation reloads settle
/// without remounting the whole app (used after flipping the visibility flag).
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final cardFinder = find.byType(ActivityCard);

  // Ten distinct, newest-first entries.
  List<LogInfo> sampleLogs() => List.generate(
    10,
    (i) => _log(DateTime.utc(2026, 1, 20).subtract(Duration(days: i))),
  );

  Future<(IrmaRepository, _FakeLogsBridge)> buildRepo(
    List<LogInfo> logs,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final bridge = _FakeLogsBridge(logs);
    final repo = IrmaRepository(
      client: bridge,
      preferences: await IrmaPreferences.fromInstance(
        mostRecentTermsUrlNl: "",
        mostRecentTermsUrlEn: "",
      ),
    );
    return (repo, bridge);
  }

  testWidgets(
    "shows a stable number of entries when extra logs arrive on the shared bus",
    (tester) async {
      final (repo, bridge) = await buildRepo(sampleLogs());
      addTearDown(repo.close);
      final show = ValueNotifier(true);
      addTearDown(show.dispose);

      await _pump(tester, _host(repo, show));

      // Its own LoadLogsEvent(max: 2) is answered with two entries.
      expect(cardFinder, findsNWidgets(2));

      // A wider log response (e.g. the Activity tab's max: 10 load) lands on
      // the shared event bus while Recent Activity is still subscribed. Before
      // the fix this got accumulated and the count jumped to 12.
      bridge.emitStrayLogs(sampleLogs());
      await _settle(tester);

      expect(
        cardFinder,
        findsNWidgets(2),
        reason: "Recent Activity must stay capped at amountOfLogs (#126)",
      );
    },
  );

  testWidgets(
    "shows the same number of entries after navigating away and back",
    (tester) async {
      final (repo, bridge) = await buildRepo(sampleLogs());
      addTearDown(repo.close);
      final show = ValueNotifier(true);
      addTearDown(show.dispose);

      // Fresh launch: home tab shows Recent Activity, capped at 2.
      await _pump(tester, _host(repo, show));
      expect(cardFinder, findsNWidgets(2));

      // Navigate to another tab. The Activity tab dispatches LoadLogsEvent(max:
      // 10); that request is still in flight when the user navigates back.
      show.value = false;
      await _settle(tester);
      expect(cardFinder, findsNothing);

      // Navigate back to the home tab: RecentActivity remounts and re-subscribes
      // to the shared event bus.
      show.value = true;
      await _settle(tester);
      expect(cardFinder, findsNWidgets(2));

      // Now the in-flight broad LogsEvent lands on the shared bus while the
      // remounted RecentActivity is subscribed. Before the fix this inflated
      // the count (the symptom reported in #126: a different number of entries
      // after navigating away and back). It must stay equal to the fresh count.
      bridge.emitStrayLogs(sampleLogs());
      await _settle(tester);

      expect(
        cardFinder,
        findsNWidgets(2),
        reason:
            "count must match the fresh-launch count after navigation (#126)",
      );
    },
  );
}

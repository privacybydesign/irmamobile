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

void main() {
  late IrmaRepository repo;
  late RecordingBridge bridge;
  final log = _log(25);

  setUp(() async {
    bridge = RecordingBridge()
      ..respond = (event) {
        if (event is! LoadLogsEvent) return null;
        final before = event.before;
        return LogsEvent(
          logEntries: log
              .where((e) => before == null || e.time.isBefore(before))
              .take(event.max)
              .toList(),
        );
      };
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

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

  testWidgets("tags filter by kind; All shows everything again", (
    tester,
  ) async {
    await pump(tester);
    expect(find.text("Shop 0"), findsOneWidget);

    await tester.tap(find.byKey(const Key("activity_tag_shared")));
    await _settle(tester);
    expect(find.text("Shop 0"), findsOneWidget);

    await tester.tap(find.byKey(const Key("activity_tag_received")));
    await _settle(tester, rounds: 40);
    expect(find.byType(ActivityCard), findsNothing);
    expect(find.text("Nothing received yet"), findsOneWidget);

    await tester.tap(find.byKey(const Key("activity_tag_all")));
    await _settle(tester);
    expect(find.text("Shop 0"), findsOneWidget);
  });

  testWidgets("a tag keeps loading older pages until it finds entries", (
    tester,
  ) async {
    await pump(tester);
    expect(find.text("Gemeente"), findsNothing);

    await tester.ensureVisible(find.byKey(const Key("activity_tag_signed")));
    await tester.pump();
    await tester.tap(find.byKey(const Key("activity_tag_signed")));
    await _settle(tester, rounds: 40);
    expect(find.text("Gemeente"), findsOneWidget);
    expect(find.text("Shop 0"), findsNothing);

    // Each page starts before the oldest entry loaded so far.
    final befores = bridge.dispatched
        .whereType<LoadLogsEvent>()
        .map((e) => e.before)
        .whereType<DateTime>()
        .toList();
    expect(befores, isNotEmpty);
    for (var i = 1; i < befores.length; i++) {
      expect(befores[i].isBefore(befores[i - 1]), isTrue);
    }
  });

  testWidgets("search and tag together", (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key("activity_tag_shared")));
    await _settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key("activity_search_field")),
        matching: find.byType(EditableText),
      ),
      "Shop 7",
    );
    await _settle(tester);
    expect(find.byType(ActivityCard), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ActivityCard),
        matching: find.text("Shop 7"),
      ),
      findsOneWidget,
    );
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

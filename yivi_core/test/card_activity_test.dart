import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/activity_providers.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";
import "package:yivi_core/src/screens/data/credential_detail/card_activity_section.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/home/widgets/irma_nav_bar.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";

class _FixedOrder extends SchemalessCredentialOrderController {
  _FixedOrder(this.items);
  final List<Credential> items;
  @override
  Future<List<Credential>> build() async => items;
}

final _card = testCredential(
  type: "pbdf.sidn-pbdf.email",
  hash: "email-card",
  name: "Email address",
  attributes: [stringAttr("email", "s.devries@werk.example")],
);

TrustedParty _party(String name) =>
    TrustedParty(id: name, name: name, url: null, parent: null, verified: true);

LogCredential _logged() => LogCredential(
  credentialId: "pbdf.sidn-pbdf.email",
  formats: const [CredentialFormat.idemix],
  name: "Email address",
  issuer: _party("Yivi"),
  attributes: [stringAttr("email", "s.devries@werk.example")],
  revoked: false,
  revocationSupported: false,
  hash: "email-card",
);

LogInfo _shared(String id, String who, DateTime time) => LogInfo(
  id: id,
  type: LogType.disclosure,
  time: time,
  issuanceLog: null,
  disclosureLog: DisclosureLog(
    protocol: Protocol.irma,
    credentials: [_logged()],
    verifier: _party(who),
  ),
  signedMessageLog: null,
  removalLog: null,
);

void main() {
  late IrmaRepository repo;
  late RecordingBridge bridge;
  late HomeTabState tabs;
  final log = [
    for (var i = 0; i < 7; i++)
      _shared("e$i", "Shop $i", DateTime.utc(2026, 10, 20 - i, 12)),
  ];

  setUp(() async {
    tabs = HomeTabState();
    bridge = RecordingBridge()
      ..respond = (event) => switch (event) {
        QueryLogsEvent() => LogPageEvent(
          requestId: event.requestId,
          page: LogPage(
            entries: log.take(event.query.limit ?? 20).toList(),
            counts: LogCounts(total: log.length, byType: const {}),
          ),
        ),
        ListPartiesEvent() => PartiesEvent(
          requestId: event.requestId,
          parties: [
            for (final e in log)
              PartySummary(
                key: e.requestor!.id,
                party: e.requestor!,
                lastTime: e.time,
                count: 1,
                byType: const {LogType.disclosure: 1},
              ),
          ],
        ),
        _ => null,
      };
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
  });
  tearDown(() async {
    await tabs.close();
    await repo.close();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pump(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1400);
    addTearDown(tester.view.reset);
    await pumpHome(
      tester,
      repo: repo,
      overrides: <Override>[
        irmaRepositoryProvider.overrideWithValue(repo),
        schemalessCredentialOrderControllerProvider.overrideWith(
          () => _FixedOrder([_card]),
        ),
      ],
      home: BlocProvider<HomeTabState>.value(
        value: tabs,
        child: SingleChildScrollView(
          child: CardActivitySection(credential: _card),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets("a card lists its newest five, with a summary", (tester) async {
    await pump(tester);

    // irmago is asked for this card's entries only.
    final query = bridge.dispatched.whereType<QueryLogsEvent>().last.query;
    expect(query.filter.credentialHash, "email-card");
    expect(query.limit, cardActivityLimit);

    expect(find.text("Shop 0"), findsOneWidget);
    expect(find.text("Shop 4"), findsOneWidget);
    expect(find.text("Shop 5"), findsNothing);
    expect(
      tester.getTopLeft(find.text("Shop 0")).dy,
      lessThan(tester.getTopLeft(find.text("Shop 1")).dy),
    );
    expect(
      find.textContaining("Shared 7 times with 7 parties"),
      findsOneWidget,
    );
    expect(find.text("See all (7)"), findsOneWidget);
  });

  testWidgets("a row opens the entry over the card; back returns", (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key("card_activity_e0")));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key("card_activity_entry")), findsOneWidget);

    await tester.tap(find.byKey(const Key("card_activity_entry_back")));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key("card_activity_entry")), findsNothing);
    expect(find.text("Shop 0"), findsOneWidget);
  });

  testWidgets("See all opens Activity, asking about this card", (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key("card_activity_see_all")));
    await settle(tester);
    expect(tabs.state, IrmaNavBarTab.activity);

    final last = bridge.dispatched.whereType<QueryLogsEvent>().last.query;
    expect(last.filter.credentialHash, "email-card");
    expect(last.limit, activityPageSize);
  });
}

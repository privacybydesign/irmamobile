import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_provider.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/data/wallet/issuance_flight.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/home/widgets/irma_nav_bar.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/credential_card_art.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";

class _FixedOrder extends SchemalessCredentialOrderController {
  _FixedOrder(this.items);

  final List<Credential> items;

  @override
  Future<List<Credential>> build() async => items;
}

final _received = testCredential(type: "pbdf.sidn-pbdf.email", hash: "new");
final _older = [
  testCredential(type: "pbdf.gemeente.personalData", hash: "old1"),
  testCredential(type: "pbdf.sidn-pbdf.mobilenumber", hash: "old2"),
];

void main() {
  late IrmaRepository repo;
  late HomeTabState tabs;

  setUp(() async {
    repo = IrmaRepository(
      client: RecordingBridge(),
      preferences: await freshPreferences(),
    );
    tabs = HomeTabState();
  });
  tearDown(() async {
    IssuanceFlight.reset();
    await tabs.close();
    await repo.close();
  });

  final sourceKey = GlobalKey(debugLabel: "source");
  late BuildContext sourceContext;

  /// The data tab with, on top of it, the success screen's card that the
  /// flight starts from.
  Future<void> pump(
    WidgetTester tester, {
    required List<Credential> wallet,
    bool reduceMotion = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1200);
    addTearDown(tester.view.reset);
    await pumpHome(
      tester,
      repo: repo,
      overrides: [
        schemalessCredentialsProvider.overrideWith(
          (ref) => Stream.value((credentials: wallet, problematic: [])),
        ),
        schemalessCredentialOrderControllerProvider.overrideWith(
          () => _FixedOrder(wallet),
        ),
      ],
      home: BlocProvider<HomeTabState>.value(
        value: tabs,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reduceMotion),
            child: Stack(
              children: [
                Positioned.fill(child: DataTab()),
                Positioned(
                  left: 40,
                  top: 700,
                  child: Builder(
                    builder: (context) {
                      sourceContext = context;
                      return CredentialCardArt(
                        key: sourceKey,
                        credential: _received,
                        width: 300,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await settle(tester);
    await tester.pumpAndSettle();
  }

  Finder tile(Credential c) => find.byKey(Key("${c.credentialId}_tile"));
  final flyingCard = find.byKey(const Key("issuance_flight_card"));

  bool hidden(WidgetTester tester, Credential c) => tester
      .widgetList<Opacity>(
        find.ancestor(of: tile(c), matching: find.byType(Opacity)),
      )
      .any((o) => o.opacity == 0);

  testWidgets("stack: flies into the first slot, the others make room", (
    tester,
  ) async {
    await pump(tester, wallet: [_received, ..._older]);
    tabs.add(IrmaNavBarTab.activity);

    final firstSlot = tester.getTopLeft(tile(_received));
    final secondSlot = tester.getTopLeft(tile(_older.first));
    expect(
      IssuanceFlight.start(
        sourceContext,
        received: _received,
        source: sourceKey,
      ),
      isTrue,
    );
    await tester.pump();
    expect(tabs.state, IrmaNavBarTab.data);

    // It starts on the success card, and the list has not made room yet.
    expect(tester.getTopLeft(flyingCard), const Offset(40, 700));
    expect(tile(_received), findsNothing);
    expect(tester.getTopLeft(tile(_older.first)), firstSlot);

    // From 420 ms the new card is in the list, hidden, and the others
    // slide down.
    await tester.pump(const Duration(milliseconds: 450));
    expect(tile(_received), findsOneWidget);
    expect(hidden(tester, _received), isTrue);
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getTopLeft(tile(_older.first)), secondSlot);

    // After the 760 ms flight it sits on the first slot.
    expect(tester.getTopLeft(flyingCard), firstSlot);

    // The stack ends at 1120 ms: the copy is gone, the real card shows.
    await tester.pump(const Duration(milliseconds: 300));
    expect(flyingCard, findsNothing);
    expect(IssuanceFlight.state.value, isNull);
    expect(hidden(tester, _received), isFalse);
    expect(tester.getTopLeft(tile(_received)), firstSlot);
  });

  testWidgets("list view ends sooner, at 840 ms", (tester) async {
    await repo.preferences.setWalletView("list");
    await pump(tester, wallet: [_received, ..._older]);

    IssuanceFlight.start(sourceContext, received: _received, source: sourceKey);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 860));
    expect(flyingCard, findsNothing);
    expect(IssuanceFlight.state.value, isNull);
  });

  testWidgets("reduce motion: only the curtain fades", (tester) async {
    await pump(tester, wallet: [_received, ..._older], reduceMotion: true);

    expect(
      IssuanceFlight.start(
        sourceContext,
        received: _received,
        source: sourceKey,
      ),
      isTrue,
    );
    await tester.pump();
    expect(flyingCard, findsNothing);
    expect(tile(_received), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    expect(IssuanceFlight.state.value, isNull);
  });

  testWidgets("from the Add data sheet: the card that leads the wallet flies", (
    tester,
  ) async {
    await pump(tester, wallet: [_received, ..._older]);

    // Of several received cards, the one that is first in the wallet.
    expect(
      IssuanceFlight.startFirstOf(
        sourceContext,
        received: [_older.last, _received],
        sources: [GlobalKey(), sourceKey],
        curtain: false,
      ),
      isTrue,
    );
    await tester.pump();
    expect(tester.getTopLeft(flyingCard), const Offset(40, 700));
    await tester.pumpAndSettle();
    expect(flyingCard, findsNothing);
    expect(tile(_received), findsOneWidget);
    expect(hidden(tester, _received), isFalse);
  });

  testWidgets("from the Add data sheet with reduce motion: nothing at all", (
    tester,
  ) async {
    await pump(tester, wallet: [_received, ..._older], reduceMotion: true);
    expect(
      IssuanceFlight.startFirstOf(
        sourceContext,
        received: [_received],
        sources: [sourceKey],
        curtain: false,
      ),
      isTrue,
    );
    await tester.pump();
    expect(flyingCard, findsNothing);
    await tester.pump(const Duration(milliseconds: 50));
    expect(IssuanceFlight.state.value, isNull);
  });

  testWidgets("no flight when the new card is not the first one", (
    tester,
  ) async {
    // Re-issued in place: the instance keeps its old position.
    await pump(tester, wallet: [..._older, _received]);

    expect(
      IssuanceFlight.start(
        sourceContext,
        received: _received,
        source: sourceKey,
      ),
      isFalse,
    );
    await tester.pump();
    expect(flyingCard, findsNothing);
    expect(IssuanceFlight.state.value, isNull);
  });

  testWidgets("Done closes as usual when the card cannot fly", (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1200);
    addTearDown(tester.view.reset);
    var dismissed = 0;
    // An empty wallet: the received card is not in the list to fly to.
    await pumpHome(
      tester,
      repo: repo,
      overrides: [
        schemalessCredentialOrderControllerProvider.overrideWith(
          () => _FixedOrder(const []),
        ),
      ],
      home: BlocProvider<HomeTabState>.value(
        value: tabs,
        child: IssuanceSuccessScreen(
          credentials: [_received],
          flyHome: true,
          onDismiss: (_) => dismissed++,
        ),
      ),
    );
    await settle(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key("ok_button")));
    await tester.pump();
    expect(dismissed, 1);
    expect(flyingCard, findsNothing);
  });
}

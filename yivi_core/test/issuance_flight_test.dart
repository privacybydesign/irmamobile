import "package:flutter/rendering.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/providers/credentials_provider.dart";
import "package:yivi_core/src/providers/wallet_cards_provider.dart";
import "package:yivi_core/src/screens/data/card_transition/card_slots.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/data/wallet/issuance_flight.dart";
import "package:yivi_core/src/screens/home/widgets/home_tab.dart";
import "package:yivi_core/src/screens/session/result/issuance_success_screen.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/credential_card_art.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";

class _FixedOrder extends CredentialOrderController {
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

  setUp(() async {
    repo = IrmaRepository(
      client: RecordingBridge(),
      preferences: await freshPreferences(),
    );
  });
  tearDown(() async {
    IssuanceFlight.reset();
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
        credentialsProvider.overrideWith(
          (ref) => Stream.value((credentials: wallet, problematic: [])),
        ),
        credentialOrderControllerProvider.overrideWith(
          () => _FixedOrder(wallet),
        ),
      ],
      home: Builder(
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
    _tabs(tester).read(homeTabProvider.notifier).select(HomeTab.activity);

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
    expect(_tabs(tester).read(homeTabProvider), HomeTab.data);

    // It starts on the success card, and the list has not made room yet.
    expect(tester.getTopLeft(flyingCard), const Offset(40, 700));
    expect(tile(_received), findsNothing);
    expect(tester.getTopLeft(tile(_older.first)), firstSlot);

    // From 190 ms, as it is picked up, the new card is in the list,
    // hidden, and the others slide down.
    await tester.pump(const Duration(milliseconds: 200));
    expect(tile(_received), findsOneWidget);
    expect(hidden(tester, _received), isTrue);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getTopLeft(tile(_older.first)), secondSlot);

    // After the 950 ms flight the real card shows on the first slot; the
    // copy goes two frames later.
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(flyingCard, findsNothing);
    expect(IssuanceFlight.state.value, isNull);
    expect(hidden(tester, _received), isFalse);
    expect(tester.getTopLeft(tile(_received)), firstSlot);
  });

  testWidgets("reduce motion: nothing flies, the session closes as usual", (
    tester,
  ) async {
    await pump(tester, wallet: [_received, ..._older], reduceMotion: true);

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
    expect(tile(_received), findsOneWidget);
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
      isFalse,
    );
    await tester.pump();
    expect(flyingCard, findsNothing);
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
        credentialOrderControllerProvider.overrideWith(
          () => _FixedOrder(const []),
        ),
      ],
      home: IssuanceSuccessScreen(
        credentials: [_received],
        flyHome: true,
        onDismiss: (_) => dismissed++,
      ),
    );
    await settle(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key("ok_button")));
    await tester.pump();
    expect(dismissed, 1);
    expect(flyingCard, findsNothing);
  });

  testWidgets("a flying card slides under the card below its place", (
    tester,
  ) async {
    const green = Color(0xFF00FF00), blue = Color(0xFF0000FF);
    const red = Color(0xFFFF0000);
    final key = GlobalKey();
    final fly = AnimationController(vsync: const TestVSync());
    addTearDown(fly.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                children: [
                  // The stack: the card at index 1 is drawn over index 0.
                  const Positioned(
                    left: 0,
                    top: 0,
                    width: 300,
                    height: 190,
                    child: CardSlot(
                      hash: "a",
                      view: CardSlotView.stack,
                      index: 0,
                      child: ColoredBox(color: green),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    top: 64,
                    width: 300,
                    height: 190,
                    child: CardSlot(
                      hash: "b",
                      view: CardSlotView.stack,
                      index: 1,
                      child: ColoredBox(color: blue),
                    ),
                  ),
                  // Card "a" flying in, drawn over everything.
                  Positioned(
                    left: 0,
                    top: 32,
                    width: 300,
                    height: 190,
                    child: CoveredByStack(
                      hash: "a",
                      repaint: fly,
                      child: const ColoredBox(color: red),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final image = await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      return (await image.toByteData())!;
    });
    Color at(int x, int y) {
      final i = (y * 300 + x) * 4;
      return Color.fromARGB(
        image!.getUint8(i + 3),
        image.getUint8(i),
        image.getUint8(i + 1),
        image.getUint8(i + 2),
      );
    }

    // Over the card above its place, under the card below it.
    expect(at(150, 48), red);
    expect(at(150, 150), blue);
  });
}

/// The provider container the app under test reads its tab from.
ProviderContainer _tabs(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first));

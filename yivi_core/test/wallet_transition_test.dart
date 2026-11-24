import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/data/wallet/wallet_transition.dart";
import "package:yivi_core/src/widgets/surfaces/base64_image.dart";
import "package:yivi_core/src/widgets/surfaces/surface.dart";

import "support/pump_translated.dart";
import "support/test_app.dart";

// A 1x1 PNG.
const _png =
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==";

void main() {
  group("card opening", () {
    late GoRouter router;
    late BuildContext tappedCard;

    setUp(() {
      WalletTransition.openKey.value = null;
      router = GoRouter(
        routes: [
          GoRoute(
            path: "/",
            pageBuilder: (context, state) => MaterialPage(
              child: Scaffold(
                body: Stack(
                  children: [
                    const Positioned(
                      top: 40,
                      left: 0,
                      right: 0,
                      height: 48,
                      child: PushAway(
                        direction: PushAwayDirection.up,
                        child: SizedBox(key: Key("search"), height: 48),
                      ),
                    ),
                    const Positioned(
                      top: 120,
                      left: 0,
                      right: 0,
                      height: 100,
                      child: PushAway(
                        hash: "above",
                        child: SizedBox(key: Key("above"), height: 100),
                      ),
                    ),
                    Positioned(
                      top: 300,
                      left: 0,
                      right: 0,
                      height: 100,
                      child: PushAway(
                        hash: "tapped",
                        child: Builder(
                          builder: (context) {
                            tappedCard = context;
                            return const SizedBox(
                              key: Key("tapped"),
                              height: 100,
                            );
                          },
                        ),
                      ),
                    ),
                    const Positioned(
                      top: 500,
                      left: 0,
                      right: 0,
                      height: 100,
                      child: PushAway(
                        hash: "below",
                        child: SizedBox(key: Key("below"), height: 100),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            routes: [
              GoRoute(
                path: "detail",
                pageBuilder: (context, state) => const WalletDetailPage(
                  child: SizedBox.expand(key: Key("detail")),
                ),
              ),
            ],
          ),
        ],
      );
    });
    tearDown(() => router.dispose());

    testWidgets("everything above moves up, below moves down, the card "
        "stays", (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      Offset at(String key) => tester.getTopLeft(find.byKey(Key(key)));
      final search = at("search");
      final above = at("above");
      final tapped = at("tapped");
      final below = at("below");

      WalletTransition.begin(tappedCard, "tapped");
      router.push("/detail");
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(at("search").dy, lessThan(search.dy));
      expect(at("above").dy, lessThan(above.dy));
      expect(at("tapped"), tapped);
      expect(at("below").dy, greaterThan(below.dy));

      // Off screen at the end; the home page itself did not slide away.
      await tester.pumpAndSettle();
      expect(at("search").dy + 48, lessThanOrEqualTo(0));
      expect(at("below").dy, greaterThanOrEqualTo(844));
      expect(at("tapped"), tapped);

      // And back again when the detail closes, without a bounce: the card
      // below never runs past its place.
      router.pop();
      WalletTransition.openKey.value = "tapped";
      WalletTransition.closing = true;
      var highest = double.infinity;
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        highest = at("below").dy < highest ? at("below").dy : highest;
      }
      expect(highest, greaterThanOrEqualTo(below.dy));
      WalletTransition.closing = false;
      await tester.pumpAndSettle();
      expect(at("search"), search);
      expect(at("below"), below);
    });
  });

  testWidgets("under a home tab's bar, as Wallet: the header fades where it "
      "is, the other cards drop away, above ones too", (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    WalletTransition.openKey.value = null;
    late BuildContext tappedCard;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: "/",
          pageBuilder: (context, state) => MaterialPage(
            child: Scaffold(
              body: WalletBar(
                plusTurnsIntoClose: true,
                child: Stack(
                  children: [
                    const Positioned(
                      top: 120,
                      left: 0,
                      right: 0,
                      height: 48,
                      child: PushAway(
                        direction: PushAwayDirection.up,
                        child: SizedBox(key: Key("field"), height: 48),
                      ),
                    ),
                    const Positioned(
                      top: 190,
                      left: 0,
                      right: 0,
                      height: 100,
                      child: PushAway(
                        hash: "above",
                        child: SizedBox(key: Key("above"), height: 100),
                      ),
                    ),
                    Positioned(
                      top: 300,
                      left: 0,
                      right: 0,
                      height: 100,
                      child: PushAway(
                        hash: "tapped",
                        child: Builder(
                          builder: (context) {
                            tappedCard = context;
                            return const SizedBox(height: 100);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          routes: [
            GoRoute(
              path: "detail",
              pageBuilder: (context, state) =>
                  const WalletDetailPage(child: SizedBox.expand()),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    WalletTransition.begin(tappedCard, "tapped");
    // The + of the bar turns into the close button.
    expect(WalletTransition.closeFromPlus, isTrue);
    router.push("/detail");
    await tester.pumpAndSettle();

    // The header: where it was, faded out.
    final field = tester.getRect(find.byKey(const Key("field")));
    expect(field.top, 120);
    expect(
      tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.byKey(const Key("field")),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity,
      0,
    );
    // The card above the tapped one went down, off the screen (by the
    // screen and its own height, so even the top one leaves).
    expect(
      tester.getTopLeft(find.byKey(const Key("above"))).dy,
      190 + 844 + 32 + 100,
    );
    WalletTransition.openKey.value = null;
  });

  test("the close button takes over from a + at the end, or turns in", () {
    WalletTransition.closeFromPlus = true;
    expect(WalletTransition.closeButton(0.1).$1, 0);
    expect(WalletTransition.closeButton(1), (1.0, 0.0));
    WalletTransition.closeFromPlus = false;
    final (opacity, turn) = WalletTransition.closeButton(0.4);
    expect(opacity, greaterThan(0));
    expect(turn, lessThan(0));
    expect(WalletTransition.closeButton(1), (1.0, 0.0));
  });

  group("card images", () {
    test("the same base64 decodes to the same bytes", () {
      expect(
        identical(decodeBase64Cached(_png), decodeBase64Cached(_png)),
        isTrue,
      );
    });

    testWidgets("a rebuilt logo uses the cached image, so it does not "
        "flicker", (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              SizedBox.square(
                dimension: 40,
                child: Base64Image(key: const Key("a"), base64: _png),
              ),
              SizedBox.square(
                dimension: 40,
                child: Base64Image(key: const Key("b"), base64: _png),
              ),
            ],
          ),
        ),
      );
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images, hasLength(2));
      // Equal providers share one entry in the image cache.
      expect(images[0].image, images[1].image);
    });
  });

  group("fading surfaces", () {
    Future<void> pumpGlass(WidgetTester tester, double opacity) =>
        pumpTranslated(
          tester,
          testApp(
            Scaffold(
              body: Center(
                child: Surface(
                  shape: const CircleBorder(),
                  opacity: opacity,
                  child: const SizedBox.square(
                    dimension: 44,
                    child: Icon(Icons.close, key: Key("icon")),
                  ),
                ),
              ),
            ),
          ),
        );

    testWidgets("only the content fades through a layer; fully in, none", (
      tester,
    ) async {
      await pumpGlass(tester, 0.5);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(
        find.ancestor(
          of: find.byKey(const Key("icon")),
          matching: find.byType(Opacity),
        ),
        findsOneWidget,
      );

      await pumpGlass(tester, 1);
      expect(
        find.ancestor(
          of: find.byKey(const Key("icon")),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    });
  });

  testWidgets("a surface is solid and flat: no sheen, no blur", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: const Scaffold(
          body: Center(child: Surface(child: SizedBox(width: 100, height: 44))),
        ),
      ),
    );
    final decorations = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(Surface),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((b) => b.decoration)
        .whereType<ShapeDecoration>();
    expect(decorations.where((d) => d.gradient != null), isEmpty);
    expect(
      decorations.where((d) => d.color != null).map((d) => d.color!.a),
      everyElement(1.0),
    );
    expect(find.byType(BackdropFilter), findsNothing);
  });
}

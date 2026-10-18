import "package:flutter/rendering.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/data/wallet/wallet_transition.dart";
import "package:yivi_core/src/widgets/base64_image.dart";
import "package:yivi_core/src/widgets/glass/glass_surface.dart";

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

      // And back again when the detail closes, with a slight bounce: the
      // card below runs a little past its place before settling.
      router.pop();
      WalletTransition.openKey.value = "tapped";
      WalletTransition.closing = true;
      var highest = double.infinity;
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        highest = at("below").dy < highest ? at("below").dy : highest;
      }
      expect(highest, lessThan(below.dy - 2));
      WalletTransition.closing = false;
      await tester.pumpAndSettle();
      expect(at("search"), search);
      expect(at("below"), below);
    });
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

  group("fading glass", () {
    Future<void> pumpGlass(WidgetTester tester, double opacity) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: GlassPillButton(
                  label: "Done",
                  onTap: () {},
                  opacity: opacity,
                ),
              ),
            ),
          ),
        );

    testWidgets("the blur is never inside an opacity layer, so it does not "
        "darken and pop at the end of the fade", (tester) async {
      await pumpGlass(tester, 0.5);

      final blur = find.byType(BackdropFilter);
      expect(blur, findsOneWidget);
      // No fading layer between the button and its blur.
      Finder inButton(Type type) => find.descendant(
        of: find.byType(GlassPillButton),
        matching: find.byType(type),
      );
      for (final layer in [Opacity, FadeTransition]) {
        expect(
          find.ancestor(of: blur, matching: inButton(layer)),
          findsNothing,
        );
      }
      // Only the label fades through a layer.
      expect(
        find.ancestor(of: find.text("Done"), matching: find.byType(Opacity)),
        findsOneWidget,
      );
    });

    testWidgets("fully faded out there is no blur; fully in, no layer", (
      tester,
    ) async {
      await pumpGlass(tester, 0);
      expect(find.byType(BackdropFilter), findsNothing);

      await pumpGlass(tester, 1);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(
        find.ancestor(of: find.text("Done"), matching: find.byType(Opacity)),
        findsNothing,
      );
    });
  });

  testWidgets("dark glass has only a faint sheen", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: const Scaffold(
          body: Center(
            child: GlassSurface(child: SizedBox(width: 100, height: 44)),
          ),
        ),
      ),
    );
    final sheen = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(GlassSurface),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((b) => b.decoration)
        .whereType<ShapeDecoration>()
        .map((d) => d.gradient)
        .whereType<LinearGradient>()
        .single;
    expect(sheen.colors.first.a, lessThan(0.1));
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
                    child: WalletStackSlot(
                      hash: "a",
                      index: 0,
                      child: ColoredBox(color: green),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    top: 64,
                    width: 300,
                    height: 190,
                    child: WalletStackSlot(
                      hash: "b",
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

import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/data/card_transition/card_origin.dart";
import "package:yivi_core/src/screens/data/card_transition/card_transition.dart";
import "package:yivi_core/src/screens/data/card_transition/choreography.dart";
import "package:yivi_core/src/widgets/surfaces/base64_image.dart";
import "package:yivi_core/src/widgets/surfaces/surface.dart";

import "support/pump_translated.dart";
import "support/test_app.dart";

// A 1x1 PNG.
const _png =
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==";

void main() {
  test("the details' ✕ takes over from a + at the end, or turns in", () {
    CardTransition at(CardOrigin origin) => CardTransition(
      choreography: Choreography(
        TransitionSnapshot(
          origin: origin,
          hash: "card",
          picked: 0,
          cards: const [Rect.fromLTWH(24, 600, 88, 55)],
          target: const Rect.fromLTWH(16, 120, 358, 226),
          screenHeight: 844,
        ),
        CardMotion.defaults,
      ),
      details: (_, _) => const SizedBox(),
      vsync: const TestVSync(),
      onDone: () {},
    );
    // Opening, at the tap: the ✕ is not there yet.
    final fromPlus = at(CardOrigin.listRow);
    expect(fromPlus.closeButton.$1, 0);
    final turning = at(CardOrigin.notification);
    expect(turning.closeButton, (0.0, -45.0));
    fromPlus.dispose();
    turning.dispose();
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

import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/widgets/glass/glass_surface.dart";
import "package:yivi_core/src/widgets/glass/pill_buttons.dart";

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: Center(
            child: SizedBox(width: 300, child: Center(child: child)),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group("pill sizes", () {
    for (final size in PillSize.values) {
      testWidgets("a fancy and a text pill of size ${size.name} are "
          "${size.height} high", (tester) async {
        await _pump(
          tester,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FancyPillButton(
                key: const Key("fancy"),
                label: "Share",
                onPressed: () {},
                size: size,
              ),
              PillButton(
                key: const Key("text"),
                label: "Cancel",
                style: PillStyle.text,
                onPressed: () {},
                size: size,
              ),
            ],
          ),
        );
        expect(
          tester.getSize(find.byKey(const Key("fancy"))).height,
          size.height,
        );
        expect(
          tester.getSize(find.byKey(const Key("text"))).height,
          size.height,
        );
      });
    }

    testWidgets("the defaults: fancy large, the others regular", (
      tester,
    ) async {
      await _pump(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FancyPillButton(
              key: const Key("fancy"),
              label: "Share",
              onPressed: () {},
            ),
            PillButton(
              key: const Key("outlined"),
              label: "Help",
              onPressed: () {},
            ),
          ],
        ),
      );
      expect(tester.getSize(find.byKey(const Key("fancy"))).height, 56);
      expect(tester.getSize(find.byKey(const Key("outlined"))).height, 52);
    });

    testWidgets("large text makes a pill taller instead of clipping it", (
      tester,
    ) async {
      await _pump(
        tester,
        FancyPillButton(
          key: const Key("fancy"),
          label: "A rather long label that has to wrap at a large size",
          onPressed: () {},
          size: PillSize.regular,
        ),
        textScale: 2,
      );
      expect(
        tester.getSize(find.byKey(const Key("fancy"))).height,
        greaterThan(52),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group("styles", () {
    testWidgets("every pill label is Alexandria 16 bold", (tester) async {
      await _pump(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FancyPillButton(label: "Primary", onPressed: () {}),
            for (final style in PillStyle.values)
              PillButton(label: style.name, style: style, onPressed: () {}),
          ],
        ),
      );
      for (final label in [
        "Primary",
        for (final style in PillStyle.values) style.name,
      ]) {
        final text = tester.widget<Text>(find.text(label));
        expect(text.style?.fontFamily, contains("Alexandria"), reason: label);
        expect(text.style?.fontSize, 16, reason: label);
        expect(text.style?.fontWeight, FontWeight.w700, reason: label);
      }
    });

    testWidgets("a disabled pill is half transparent and does nothing", (
      tester,
    ) async {
      await _pump(
        tester,
        const PillButton(key: Key("off"), label: "Off", onPressed: null),
      );
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: find.text("Off"), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, 0.5);
    });
  });

  group("small buttons", () {
    testWidgets("SmallPill: 32 high, at least 44 wide, Open Sans 13 semibold", (
      tester,
    ) async {
      var taps = 0;
      await _pump(
        tester,
        SmallPill(
          key: const Key("pill"),
          label: "Change",
          onPressed: () => taps++,
        ),
      );
      expect(tester.getSize(find.byKey(const Key("pill"))).height, 32);
      expect(
        tester.getSize(find.byKey(const Key("pill"))).width,
        greaterThanOrEqualTo(44),
      );
      expect(
        tester
            .getSize(
              find.descendant(
                of: find.byKey(const Key("pill")),
                matching: find.byType(Material),
              ),
            )
            .height,
        SmallPill.height,
      );
      final text = tester.widget<Text>(find.text("Change"));
      expect(text.style?.fontSize, 13);
      expect(text.style?.fontWeight, FontWeight.w600);
      await tester.tap(find.byKey(const Key("pill")));
      expect(taps, 1);
    });

    testWidgets("TextLink and PlainIconButton", (tester) async {
      await _pump(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextLink(
              key: const Key("link"),
              label: "Send again",
              onPressed: () {},
            ),
            PlainIconButton(
              key: const Key("icon"),
              icon: Icons.delete_outline_rounded,
              semanticsLabel: "Delete",
              danger: true,
              onPressed: () {},
            ),
          ],
        ),
      );
      expect(
        tester.getSize(find.byKey(const Key("link"))).height,
        greaterThanOrEqualTo(44),
      );
      expect(tester.getSize(find.byKey(const Key("icon"))), const Size(44, 44));
      final link = tester.widget<Text>(find.text("Send again"));
      expect(link.style?.decoration, TextDecoration.none);
      expect(link.style?.fontWeight, FontWeight.w600);
    });
  });

  testWidgets("a glass icon button fades through the glass, not an Opacity", (
    tester,
  ) async {
    await _pump(
      tester,
      GlassIconButton(
        icon: const Icon(Icons.close),
        semanticsLabel: "Close",
        onTap: () {},
        opacity: 0.4,
      ),
    );
    expect(tester.widget<GlassSurface>(find.byType(GlassSurface)).opacity, 0.4);
  });
}

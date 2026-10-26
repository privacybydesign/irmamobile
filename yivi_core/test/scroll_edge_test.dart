import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/glass/glass_sheet.dart";
import "package:yivi_core/src/widgets/glass/scroll_edge.dart";
import "package:yivi_core/src/widgets/glass/title_scroll_edge.dart";
import "package:yivi_core/src/widgets/irma_app_bar.dart";

import "helpers/test_translation_loader.dart";

late BuildContext _page;

Widget _app(Widget home) => IrmaTheme(
  builder: (_) => MaterialApp(
    localizationsDelegates: [
      FlutterI18nDelegate(
        translationLoader: TestTranslationLoader(
          basePath: "assets/locales",
          forcedLocale: const Locale("en", "US"),
        ),
      ),
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: Builder(
      builder: (context) {
        _page = context;
        return home;
      },
    ),
  ),
);

final _band = find.byKey(const Key("scroll_edge_band"));

Widget _rows() => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    for (var i = 0; i < 40; i++)
      SizedBox(height: 48, child: Text("row $i", key: Key("row $i"))),
  ],
);

void main() {
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(400, 800);
    view.devicePixelRatio = 1;
  });

  group("ScrollEdgeNotifier", () {
    test("0 at the top, 1 a few points in, 0 when pulled past the top", () {
      ScrollMetrics at(double pixels) => FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 1000,
        pixels: pixels,
        viewportDimension: 600,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      );
      expect(ScrollEdgeNotifier.valueOf(at(0)), 0);
      expect(ScrollEdgeNotifier.valueOf(at(3)), closeTo(0.5, 0.01));
      expect(ScrollEdgeNotifier.valueOf(at(40)), 1);
      expect(ScrollEdgeNotifier.valueOf(at(-30)), 0);
    });
  });

  group("in a sheet", () {
    Future<void> open(WidgetTester tester, {Widget? pinned}) async {
      await tester.pumpWidget(
        _app(const Scaffold(body: Center(child: Text("page")))),
      );
      await tester.pumpAndSettle();
      showGlassSheet<void>(
        context: _page,
        builder: (_) =>
            GlassSheetPage(title: "Sheet", pinned: pinned, child: _rows()),
      );
      await tester.pumpAndSettle();
    }

    testWidgets("no edge at rest; once scrolled, the content goes on under "
        "the header and the edge shows", (tester) async {
      await open(tester);
      expect(_band, findsNothing);
      final header = tester.getRect(find.byType(GlassSheetHeader));
      expect(
        tester.getRect(find.text("row 0")).top,
        greaterThan(header.bottom),
      );

      await tester.drag(find.text("row 4"), const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(_band, findsOneWidget);
      // The band runs from the sheet's top to the header's bottom.
      final band = tester.getRect(_band);
      expect(band.bottom, closeTo(header.bottom, 0.5));
      // The first row is under the header now, still built and painted
      // there (the header does not clip it).
      final row = tester.getRect(find.text("row 0"));
      expect(row.top, lessThan(header.bottom));
      expect(row.bottom, greaterThan(header.top));

      // Back at the top the edge goes again.
      await tester.drag(find.text("row 6"), const Offset(0, 120));
      await tester.pumpAndSettle();
      expect(_band, findsNothing);
    });

    testWidgets("the edge takes in the pinned part (the progress)", (
      tester,
    ) async {
      await open(
        tester,
        pinned: const SizedBox(
          key: Key("progress"),
          height: 28,
          child: Text("1 of 3"),
        ),
      );
      await tester.drag(find.text("row 4"), const Offset(0, -60));
      await tester.pumpAndSettle();
      final progress = tester.getRect(find.byKey(const Key("progress")));
      // The progress line ends the bar: the edge reaches down to it.
      expect(
        tester.getRect(_band).bottom,
        greaterThanOrEqualTo(progress.bottom),
      );
    });

    testWidgets("a tap on the header does not reach the content under it", (
      tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(
        _app(const Scaffold(body: Center(child: Text("page")))),
      );
      await tester.pumpAndSettle();
      showGlassSheet<void>(
        context: _page,
        builder: (_) => GlassSheetPage(
          title: "Sheet",
          child: Column(
            children: [
              for (var i = 0; i < 40; i++)
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => tapped++,
                    child: Text("row $i"),
                  ),
                ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.text("row 4"), const Offset(0, -120));
      await tester.pumpAndSettle();
      final header = tester.getRect(find.byType(GlassSheetHeader));
      await tester.tapAt(Offset(header.center.dx, header.bottom - 4));
      await tester.pump();
      expect(tapped, 0);
    });
  });

  testWidgets("IrmaAppBar: the edge once the page scrolls under it", (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Scaffold(
          extendBodyBehindAppBar: true,
          appBar: IrmaAppBar(titleString: "Title"),
          body: ListView(
            padding: const EdgeInsets.only(top: 100),
            children: [for (var i = 0; i < 40; i++) Text("row $i")],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_band, findsNothing);
    await tester.drag(find.text("row 5"), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(_band, findsOneWidget);
    expect(
      tester.getRect(_band).bottom,
      closeTo(
        tester.getRect(find.byKey(const Key("irma_app_bar"))).bottom,
        0.5,
      ),
    );
  });

  testWidgets("a page without a bar: the edge under the status bar", (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            padding: EdgeInsets.only(top: 47),
          ),
          child: Scaffold(
            body: ScrollEdge(
              child: ListView(
                children: [for (var i = 0; i < 40; i++) Text("row $i")],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_band, findsNothing);
    await tester.drag(find.text("row 5"), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(tester.getRect(_band), const Rect.fromLTWH(0, 0, 400, 47));
  });

  group("a band that comes with the header", () {
    testWidgets("HeaderEdgeBand: none until shown, gone again after", (
      tester,
    ) async {
      final shown = ValueNotifier(false);
      await tester.pumpWidget(
        _app(Scaffold(body: HeaderEdgeBand(shown: shown))),
      );
      await tester.pumpAndSettle();
      expect(_band, findsNothing);
      shown.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      // Fading in with the header.
      final half = tester.widget<DecoratedBox>(_band).decoration;
      expect((half as BoxDecoration).color!.a, inExclusiveRange(0, 0.7));
      await tester.pumpAndSettle();
      expect(_band, findsOneWidget);
      shown.value = false;
      await tester.pumpAndSettle();
      expect(_band, findsNothing);
    });

    testWidgets("IrmaAppBar with edgeShown: not on the first scroll", (
      tester,
    ) async {
      final shown = ValueNotifier(false);
      await tester.pumpWidget(
        _app(
          Scaffold(
            extendBodyBehindAppBar: true,
            appBar: IrmaAppBar(titleString: "Title", edgeShown: shown),
            body: ListView(
              padding: const EdgeInsets.only(top: 100),
              children: [for (var i = 0; i < 40; i++) Text("row $i")],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.text("row 5"), const Offset(0, -80));
      await tester.pumpAndSettle();
      // Scrolled under the bar, but the header is not there yet.
      expect(_band, findsNothing);
      shown.value = true;
      await tester.pumpAndSettle();
      expect(_band, findsOneWidget);
      shown.value = false;
      await tester.pumpAndSettle();
      expect(_band, findsNothing);
    });

    testWidgets("TitleScrollEdge: the band with the small title", (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: TitleScrollEdge(
              title: "More",
              largeTitleBottom: 120,
              child: ListView(
                children: [
                  const SizedBox(height: 120, child: Text("More")),
                  for (var i = 0; i < 40; i++)
                    SizedBox(height: 48, child: Text("row $i")),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final scroll = find.byType(Scrollable);
      // A little: under the bar, but the large title still shows.
      await tester.drag(scroll, const Offset(0, -40));
      await tester.pumpAndSettle();
      expect(_band, findsNothing);
      // Past the large title: the small title and the band.
      await tester.drag(scroll, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(_band, findsOneWidget);
      // Back up: both go.
      await tester.drag(scroll, const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(_band, findsNothing);
    });
  });
}

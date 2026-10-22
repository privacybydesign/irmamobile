import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/glass/glass_sheet.dart";
import "package:yivi_core/src/widgets/glass/glass_surface.dart";

import "helpers/test_translation_loader.dart";

late BuildContext _page;

/// A page with a piece of glass on it, under the app's [GlassSheetCover].
Widget _app({bool opaqueGlass = false}) => IrmaTheme(
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
    builder: (context, child) =>
        GlassSheetCover(opaqueGlass: opaqueGlass, child: child!),
    home: Builder(
      builder: (context) {
        _page = context;
        return const Scaffold(
          body: Center(
            child: GlassSurface(
              key: Key("page_glass"),
              child: SizedBox(width: 200, height: 48),
            ),
          ),
        );
      },
    ),
  ),
);

void _open() => showGlassSheet<void>(
  context: _page,
  builder: (_) => const GlassSheetPage(
    title: "Sheet",
    child: GlassSurface(
      key: Key("sheet_glass"),
      child: SizedBox(width: 200, height: 48),
    ),
  ),
);

Finder _blurIn(String key) => find.descendant(
  of: find.byKey(Key(key)),
  matching: find.byType(BackdropFilter),
);

void main() {
  setUp(() => GlassSheetCover.covering.value = 0);

  testWidgets("the sheet and the glass on it draw no blur", (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    _open();
    await tester.pumpAndSettle();
    // The sheet's own surface: opaque, no blur. Its content may hold the
    // sheet's scroll edge, which does blur; the surface itself does not.
    final sheet = tester.widget<GlassSurface>(
      find.byKey(const Key("glass_sheet")),
    );
    expect(sheet.blur, isFalse);
    expect(sheet.fill!.a, 1);
    expect(_blurIn("sheet_glass"), findsNothing);
  });

  testWidgets("the page's glass blurs until a sheet covers it, and again "
      "after", (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(_blurIn("page_glass"), findsOneWidget);

    _open();
    // While the sheet comes up, the page still shows: it still blurs.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(_blurIn("page_glass"), findsOneWidget);

    await tester.pumpAndSettle();
    expect(GlassSheetCover.covering.value, 1);
    expect(_blurIn("page_glass"), findsNothing);

    // Closing: blurring again as soon as the sheet starts to go.
    Navigator.of(_page).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(_blurIn("page_glass"), findsOneWidget);
    await tester.pumpAndSettle();
    expect(GlassSheetCover.covering.value, 0);
    expect(_blurIn("page_glass"), findsOneWidget);
  });

  testWidgets("the page under a fully open sheet is laid out but not drawn, "
      "until the sheet moves", (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final glass = find.byKey(const Key("page_glass"), skipOffstage: false);
    bool drawn() => tester
        .widgetList<Offstage>(
          find.ancestor(of: glass, matching: find.byType(Offstage)),
        )
        .every((o) => !o.offstage);

    _open();
    // Also on the first frame, when the hero controller measures the sheet
    // offstage: the screen was black for a frame.
    await tester.pump();
    expect(drawn(), isTrue);
    await tester.pump(const Duration(milliseconds: 50));
    expect(drawn(), isTrue);

    await tester.pumpAndSettle();
    expect(drawn(), isFalse);
    // Still laid out: what is on it keeps its size and state.
    expect(tester.getSize(glass), const Size(200, 48));

    Navigator.of(_page).pop();
    await tester.pump();
    expect(drawn(), isTrue);
    await tester.pumpAndSettle();
    expect(drawn(), isTrue);
  });

  testWidgets("the developer setting makes all glass opaque, without blur", (
    tester,
  ) async {
    Color fillOf(String key) => tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => box.decoration)
        .whereType<ShapeDecoration>()
        .firstWhere((d) => d.color != null)
        .color!;

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(_blurIn("page_glass"), findsOneWidget);
    expect(fillOf("page_glass").a, lessThan(1));

    await tester.pumpWidget(_app(opaqueGlass: true));
    await tester.pumpAndSettle();
    expect(_blurIn("page_glass"), findsNothing);
    expect(fillOf("page_glass").a, 1);
  });
}

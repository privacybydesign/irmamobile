import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/glass/glass_sheet.dart";
import "package:yivi_core/src/widgets/glass/glass_surface.dart";

import "helpers/test_translation_loader.dart";

late BuildContext _page;

/// A page with a surface on it.
Widget _app() => IrmaTheme(
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
  builder: (_) => GlassSheetPage(
    title: "Sheet",
    child: Column(
      children: [
        const GlassSurface(
          key: Key("sheet_glass"),
          child: SizedBox(width: 200, height: 48),
        ),
        for (var i = 0; i < 30; i++) SizedBox(height: 60, child: Text("$i")),
      ],
    ),
  ),
);

Color _fillOf(WidgetTester tester, String key) => tester
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

void main() {
  setUp(() => GlassSheetCover.covering.value = 0);

  testWidgets("no glass: surfaces are solid and nothing blurs", (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(_fillOf(tester, "page_glass").a, 1);

    _open();
    await tester.pumpAndSettle();
    expect(_fillOf(tester, "sheet_glass").a, 1);
    expect(_fillOf(tester, "glass_sheet").a, 1);
    // The sheet's content under its bar: the bar stays solid.
    await tester.drag(find.text("3"), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsNothing);
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
    expect(GlassSheetCover.covering.value, 1);
    expect(drawn(), isFalse);
    // Still laid out: what is on it keeps its size and state.
    expect(tester.getSize(glass), const Size(200, 48));

    Navigator.of(_page).pop();
    await tester.pump();
    expect(drawn(), isTrue);
    await tester.pumpAndSettle();
    expect(drawn(), isTrue);
  });
}

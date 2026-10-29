import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/glass/glass_sheet.dart";

import "helpers/test_translation_loader.dart";

late BuildContext _page;

/// As the app: under a Router, which hands the system back on.
Widget _app() => IrmaTheme(
  builder: (_) => MaterialApp.router(
    localizationsDelegates: [
      FlutterI18nDelegate(
        translationLoader: TestTranslationLoader(
          basePath: "assets/locales",
          forcedLocale: const Locale("en", "US"),
        ),
      ),
      ...GlobalMaterialLocalizations.delegates,
    ],
    routerConfig: GoRouter(
      routes: [
        GoRoute(
          path: "/",
          builder: (context, state) {
            _page = context;
            return const Scaffold(body: Center(child: Text("page")));
          },
        ),
      ],
    ),
  ),
);

/// A sheet with a subpage open.
void _openTwoPages() {
  var two = true;
  showGlassSheet<void>(
    context: _page,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        void back() => setState(() => two = false);
        return GlassSheetPages(
          onBack: back,
          pages: [
            const GlassSheetPage(
              key: ValueKey("one"),
              title: "First",
              child: Text("first page"),
            ),
            if (two)
              GlassSheetPage(
                key: const ValueKey("two"),
                title: "Second",
                onBack: back,
                child: const Text("second page"),
              ),
          ],
        );
      },
    ),
  );
}

Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  // A phone held upright (the sheet from the bottom) and a tablet (a form
  // sheet in the middle).
  for (final (device, size) in [
    ("phone", const Size(400, 800)),
    ("tablet", const Size(1024, 1366)),
  ]) {
    group(device, () {
      Future<void> open(WidgetTester tester) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = size
          ..padding = const FakeViewPadding(top: 47);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_app());
        await tester.pumpAndSettle();
        _openTwoPages();
        await tester.pumpAndSettle();
        expect(find.text("second page"), findsOneWidget);
      }

      testWidgets("the system back on a subpage goes back a page", (
        tester,
      ) async {
        await open(tester);

        await _systemBack(tester);

        expect(find.text("second page"), findsNothing);
        expect(find.text("first page"), findsOneWidget);
      });

      testWidgets("the system back on the first page closes the sheet", (
        tester,
      ) async {
        await open(tester);

        await _systemBack(tester);
        await _systemBack(tester);

        expect(find.text("first page"), findsNothing);
        expect(find.text("page"), findsOneWidget);
      });

      testWidgets("a tap outside a subpage still closes the sheet", (
        tester,
      ) async {
        await open(tester);

        await tester.tapAt(const Offset(200, 3));
        await tester.pumpAndSettle();

        expect(find.text("second page"), findsNothing);
        expect(find.text("first page"), findsNothing);
      });
    });
  }
}

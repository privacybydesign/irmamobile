import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/glass/glass_sheet.dart";
import "package:yivi_core/src/widgets/irma_close_button.dart";

import "helpers/test_translation_loader.dart";

late BuildContext _page;

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
        return const Scaffold(body: Center(child: Text("page")));
      },
    ),
  ),
);

/// A sheet whose list is taller than the sheet.
void _open() => showGlassSheet<void>(
  context: _page,
  builder: (_) => GlassSheetPage(
    title: "Sheet",
    child: Column(children: [for (var i = 0; i < 40; i++) Text("row $i")]),
  ),
);

bool _gestureStuck(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator)).userGestureInProgress;

void main() {
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(400, 800);
    view.devicePixelRatio = 1;
  });

  testWidgets("a pull taken back before letting go ends the gesture", (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    _open();
    await tester.pumpAndSettle();

    final g = await tester.startGesture(tester.getCenter(find.text("row 2")));
    await g.moveBy(const Offset(0, 40));
    await tester.pump();
    await g.moveBy(const Offset(0, 40));
    await tester.pump();
    // Back up past where it started: the pull is gone, the list scrolls.
    await g.moveBy(const Offset(0, -200));
    await tester.pump();
    await g.up();
    await tester.pumpAndSettle();

    expect(_gestureStuck(tester), isFalse);
    expect(find.text("Sheet"), findsOneWidget);
    // Still answers taps: the close button closes it.
    await tester.tap(find.byType(IrmaCloseButton));
    await tester.pumpAndSettle();
    expect(find.text("Sheet"), findsNothing);
  });

  testWidgets("a pull let go closes or springs back, and ends the gesture", (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    _open();
    await tester.pumpAndSettle();
    await tester.drag(find.text("row 2"), const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(find.text("Sheet"), findsOneWidget);
    expect(_gestureStuck(tester), isFalse);

    await tester.drag(find.text("row 2"), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.text("Sheet"), findsNothing);
    expect(_gestureStuck(tester), isFalse);
  });

  testWidgets("a drag on the header that is cancelled ends the gesture", (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    _open();
    await tester.pumpAndSettle();

    final g = await tester.startGesture(tester.getCenter(find.text("Sheet")));
    await g.moveBy(const Offset(0, 40));
    await tester.pump();
    await g.moveBy(const Offset(0, 40));
    await tester.pump();
    await g.cancel();
    await tester.pumpAndSettle();

    expect(_gestureStuck(tester), isFalse);
    expect(find.text("Sheet"), findsOneWidget);
  });
}

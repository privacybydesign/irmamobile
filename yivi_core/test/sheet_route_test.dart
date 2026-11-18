import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/buttons/close_button.dart";
import "package:yivi_core/src/widgets/sheet/sheet.dart";

import "helpers/test_translation_loader.dart";

/// What the sheet around a page tells and does for it (closing, a delayed
/// close, the hand on it, the action in the bar), on a phone and on a
/// tablet's form sheet.
late BuildContext _home;
late BuildContext _inSheet;

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
        _home = context;
        return const Scaffold(body: Center(child: Text("home")));
      },
    ),
  ),
);

void main() {
  Future<void> open(
    WidgetTester tester,
    Size size, {
    void Function(bool closing)? onPop,
    bool canPop = true,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    showSheet<void>(
      context: _home,
      builder: (_) => PopScope(
        canPop: canPop,
        onPopInvokedWithResult: (_, _) =>
            onPop?.call(Sheet.of(_inSheet).closing),
        child: SheetPage.scroll(
          title: SheetTitle("Sheet"),
          child: Builder(
            builder: (context) {
              _inSheet = context;
              return Column(
                children: [for (var i = 0; i < 30; i++) Text("row $i")],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const phone = Size(390, 844);
  const tablet = Size(1180, 820);

  testWidgets("closing: a scope that holds the sheet hears true from the "
      "close button, false from the system back", (tester) async {
    final seen = <bool>[];
    await open(tester, phone, onPop: seen.add, canPop: false);
    await tester.tap(find.byType(YiviCloseButton));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(seen, [true, false]);
    // Held: still up.
    expect(find.text("row 0"), findsOneWidget);
  });

  testWidgets("a delayed close: the sheet waits before it goes", (
    tester,
  ) async {
    Future<double> movedAfter150({required bool delayed}) async {
      await open(tester, phone);
      final top = tester.getTopLeft(find.text("row 0")).dy;
      if (delayed) {
        Sheet.of(_inSheet).delayClose(const Duration(milliseconds: 200));
      }
      Navigator.of(_inSheet).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      final moved = tester.getTopLeft(find.text("row 0")).dy - top;
      await tester.pumpAndSettle();
      expect(find.text("row 0"), findsNothing);
      return moved;
    }

    final plain = await movedAfter150(delayed: false);
    final delayed = await movedAfter150(delayed: true);
    expect(delayed, lessThan(plain));
  });

  testWidgets("the hand: dragging while the header is held, not once it "
      "settles; a tablet's form sheet has one too", (tester) async {
    await open(tester, phone);
    final hand = Sheet.of(_inSheet).hand!;
    expect(hand.dragging.value, isFalse);
    final drag = await tester.startGesture(
      tester.getCenter(find.text("Sheet")),
    );
    await drag.moveBy(const Offset(0, 40));
    await tester.pump();
    expect(hand.dragging.value, isTrue);
    await drag.moveBy(const Offset(0, -40));
    await drag.up();
    await tester.pumpAndSettle();
    expect(hand.dragging.value, isFalse);

    await open(tester, tablet);
    expect(Sheet.of(_inSheet).hand, isNotNull);
  });

  testWidgets("the action in the bar: on a tablet's form sheet and "
      "sideways; outside a sheet by the window", (tester) async {
    await open(tester, tablet);
    expect(Sheet.actionInBar(_inSheet), isTrue);
    await open(tester, phone);
    expect(Sheet.actionInBar(_inSheet), isFalse);
    expect(Sheet.actionInBar(_home), isFalse);
    await open(tester, const Size(844, 390));
    expect(Sheet.actionInBar(_home), isTrue);
  });
}

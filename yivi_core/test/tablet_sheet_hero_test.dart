import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/widgets/glass/glass_sheet.dart";

void main() {
  for (final (name, size) in [
    ("phone", const Size(390, 844)),
    ("tablet", const Size(1180, 820)),
  ]) {
    testWidgets("$name: a hero flies into the sheet", (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);

      late BuildContext home;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                home = context;
                return const Align(
                  alignment: Alignment.topLeft,
                  child: Hero(
                    tag: "card",
                    child: SizedBox(width: 100, height: 60),
                  ),
                );
              },
            ),
          ),
        ),
      );

      late BuildContext inSheet;
      showGlassSheet<void>(
        context: home,
        builder: (context) {
          inSheet = context;
          return const Center(
            child: Hero(
              tag: "card",
              child: SizedBox(width: 200, height: 120),
            ),
          );
        },
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      // A page route (a dialog's popup route would not let heroes fly).
      expect(ModalRoute.of(inSheet), isA<PageRoute<void>>());
      // Mid-flight the card is drawn by the flight, between the two sizes.
      final flying = tester.getSize(find.byType(SizedBox).last);
      expect(flying.width, greaterThan(100));
      expect(flying.width, lessThan(200));
      await tester.pumpAndSettle();
    });
  }
}

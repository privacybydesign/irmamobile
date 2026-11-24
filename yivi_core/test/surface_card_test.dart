import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/widgets/surfaces/surface_card.dart";

import "support/test_app.dart";

void main() {
  // A list row is one fixed height whether or not it is picked: its edge
  // must not take room from what is in it, or the row's last line is cut.
  for (final highContrast in [false, true]) {
    testWidgets("the selected edge takes no room"
        "${highContrast ? " (Increase Contrast)" : ""}", (tester) async {
      Future<Size> inner({required bool selected}) async {
        await tester.pumpWidget(
          testApp(
            MediaQuery(
              data: MediaQueryData(highContrast: highContrast),
              child: Center(
                child: SurfaceCard(
                  width: 300,
                  height: 100,
                  selected: selected,
                  padding: const EdgeInsets.all(8),
                  child: const SizedBox.expand(key: Key("inside")),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester.getSize(find.byKey(const Key("inside")));
      }

      expect(await inner(selected: true), const Size(284, 84));
      expect(await inner(selected: false), const Size(284, 84));
    });
  }
}

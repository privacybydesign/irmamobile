import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/session_columns.dart";

void main() {
  testWidgets("only the right column scrolls; the buttons stay in view", (
    tester,
  ) async {
    // An unfolded phone held sideways.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(951, 669);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionColumns(
            start: const SizedBox(height: 200, child: Text("who asks")),
            end: Column(
              children: [
                for (var i = 0; i < 20; i++)
                  SizedBox(height: 80, child: Text("card $i")),
              ],
            ),
            actions: ElevatedButton(
              onPressed: () {},
              child: const Text("Share"),
            ),
          ),
        ),
      ),
    );

    final asks = tester.getRect(find.text("who asks"));
    final share = tester.getRect(find.text("Share"));
    final first = tester.getRect(find.text("card 0"));

    await tester.drag(find.text("card 3"), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(tester.getRect(find.text("card 0")).top, lessThan(first.top));
    expect(tester.getRect(find.text("who asks")), asks);
    expect(tester.getRect(find.text("Share")), share);
    expect(share.bottom, lessThanOrEqualTo(669));
  });
}

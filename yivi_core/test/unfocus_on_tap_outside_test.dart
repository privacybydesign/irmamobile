import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/widgets/unfocus_on_tap_outside.dart";

void main() {
  final one = FocusNode();
  final two = FocusNode();

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      UnfocusOnTapOutside(
        child: MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                TextField(key: const Key("one"), focusNode: one),
                TextField(key: const Key("two"), focusNode: two),
                for (var i = 0; i < 40; i++)
                  SizedBox(height: 40, child: Text("row $i")),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key("one")));
    await tester.pump();
    expect(one.hasFocus, isTrue);
  }

  // On phones Flutter keeps the focus on a tap outside; this is what changes.
  final ios = TargetPlatformVariant.only(TargetPlatform.iOS);

  testWidgets("a tap outside the field puts the keyboard away", (tester) async {
    await pump(tester);
    await tester.tap(find.text("row 3"));
    await tester.pump();
    expect(one.hasFocus, isFalse);
  }, variant: ios);

  testWidgets("only when the finger lifts, not when it touches down", (
    tester,
  ) async {
    await pump(tester);
    final g = await tester.startGesture(tester.getCenter(find.text("row 3")));
    await tester.pump();
    expect(one.hasFocus, isTrue);
    await g.up();
    await tester.pump();
    expect(one.hasFocus, isFalse);
  }, variant: ios);

  testWidgets("a scroll keeps the keyboard up", (tester) async {
    await pump(tester);
    await tester.drag(find.text("row 3"), const Offset(0, -200));
    await tester.pump();
    expect(one.hasFocus, isTrue);
  }, variant: ios);

  testWidgets("a tap on another field moves the focus there", (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key("two")));
    await tester.pump();
    expect(one.hasFocus, isFalse);
    expect(two.hasFocus, isTrue);
  }, variant: ios);
}

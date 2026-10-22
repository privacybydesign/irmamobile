import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/widgets/side_panel_inset.dart";

void main() {
  /// Pumps the inset with a child that reports what it gets, and returns
  /// the child's rect and the side padding it sees.
  Future<(Rect, EdgeInsets)> pump(
    WidgetTester tester,
    Size size,
    FakeViewPadding padding,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.view.padding = padding;
    addTearDown(tester.view.reset);
    late EdgeInsets seen;
    await tester.pumpWidget(
      MaterialApp(
        home: SidePanelInset(
          child: Builder(
            builder: (context) {
              seen = MediaQuery.paddingOf(context);
              return const SizedBox.expand(key: Key("app"));
            },
          ),
        ),
      ),
    );
    return (tester.getRect(find.byKey(const Key("app"))), seen);
  }

  testWidgets("upright beside a side panel: the app gets the room beside it", (
    tester,
  ) async {
    // An iPhone Duo folded, held upright: the control bar at the right.
    final (rect, padding) = await pump(
      tester,
      const Size(466, 678),
      const FakeViewPadding(right: 84, bottom: 34),
    );
    expect(rect, const Rect.fromLTWH(0, 0, 382, 678));
    expect(padding.right, 0);
    expect(padding.bottom, 34);
  });

  testWidgets("upright without a side inset: nothing changes", (tester) async {
    final (rect, _) = await pump(
      tester,
      const Size(402, 874),
      const FakeViewPadding(top: 62, bottom: 34),
    );
    expect(rect, const Rect.fromLTWH(0, 0, 402, 874));
  });

  testWidgets("sideways: the layouts place themselves in the safe area", (
    tester,
  ) async {
    final (rect, padding) = await pump(
      tester,
      const Size(874, 402),
      const FakeViewPadding(left: 62, right: 62, bottom: 21),
    );
    expect(rect, const Rect.fromLTWH(0, 0, 874, 402));
    expect(padding.left, 62);
  });
}

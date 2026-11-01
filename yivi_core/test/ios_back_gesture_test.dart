import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/page_transitions.dart";

void main() {
  /// Two pages on iOS: the first under the second. Returns where each is.
  Future<(double Function(), double Function())> pumpPages(
    WidgetTester tester, {
    TargetPlatform platform = TargetPlatform.iOS,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: ThemeData(
          platform: platform,
          pageTransitionsTheme: yiviPageTransitionsTheme,
        ),
        home: const Scaffold(body: Text("first", key: Key("first"))),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const Scaffold(body: Text("second", key: Key("second"))),
      ),
    );
    await tester.pumpAndSettle();
    return (
      () => tester.getTopLeft(find.byKey(const Key("first"))).dx,
      () => tester.getTopLeft(find.byKey(const Key("second"))).dx,
    );
  }

  testWidgets("a back swipe let go past halfway finishes without a jump: "
      "both pages go on smoothly from where the finger left them", (
    tester,
  ) async {
    final (under, top) = await pumpPages(tester);
    final gesture = await tester.startGesture(const Offset(5, 400));
    for (var x = 5.0; x <= 245; x += 10) {
      await gesture.moveTo(Offset(x, 400));
      await tester.pump(const Duration(milliseconds: 16));
    }
    // The finger rests before it lets go: no fling.
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.moveTo(const Offset(245, 400));
    await tester.pump(const Duration(milliseconds: 300));
    var lastUnder = under(), lastTop = top();
    await gesture.up();
    var frames = 0;
    while (find.byKey(const Key("second")).evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 16));
      if (find.byKey(const Key("second")).evaluate().isEmpty) break;
      // At most 6 % of the width a frame for the page that goes, half that
      // for the one under it, from the very first frame.
      expect(top() - lastTop, lessThan(24), reason: "frame $frames");
      expect(top(), greaterThanOrEqualTo(lastTop), reason: "frame $frames");
      expect(under() - lastUnder, lessThan(12), reason: "frame $frames");
      expect(under(), greaterThanOrEqualTo(lastUnder), reason: "frame $frames");
      lastUnder = under();
      lastTop = top();
      frames++;
    }
    expect(frames, greaterThan(8), reason: "it should not end at once");
    await tester.pump();
    expect(under(), 0);
  });

  testWidgets("let go before halfway, the page goes back where it was", (
    tester,
  ) async {
    final (_, top) = await pumpPages(tester);
    final gesture = await tester.startGesture(const Offset(5, 400));
    for (var x = 5.0; x <= 105; x += 10) {
      await gesture.moveTo(Offset(x, 400));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.moveTo(const Offset(105, 400));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(top(), 0);
    expect(find.byKey(const Key("second")), findsOneWidget);
    // Covered again: the page under it is offstage.
    expect(find.byKey(const Key("first")), findsNothing);
  });

  testWidgets("Android: the back gesture moves the page, and let go it "
      "finishes without a jump", (tester) async {
    final (under, top) = await pumpPages(
      tester,
      platform: TargetPlatform.android,
    );
    Future<void> send(String method, [double progress = 0]) =>
        tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          "flutter/backgesture",
          const StandardMethodCodec().encodeMethodCall(
            MethodCall(method, <String, Object?>{
              "touchOffset": <double>[5, 400],
              "progress": progress,
              "swipeEdge": 0,
            }),
          ),
          (_) {},
        );
    await send("startBackGesture");
    for (var p = 0.05; p <= 0.6; p += 0.05) {
      await send("updateBackGestureProgress", p);
      await tester.pump(const Duration(milliseconds: 16));
    }
    // The page has followed the gesture.
    expect(top(), closeTo(0.6 * 400, 25));
    var last = top();
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      "flutter/backgesture",
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall("commitBackGesture"),
      ),
      (_) {},
    );
    var frames = 0;
    while (find.byKey(const Key("second")).evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 16));
      if (find.byKey(const Key("second")).evaluate().isEmpty) break;
      expect(top() - last, lessThan(24), reason: "frame $frames");
      expect(top(), greaterThanOrEqualTo(last), reason: "frame $frames");
      last = top();
      frames++;
    }
    expect(frames, greaterThan(4));
    await tester.pump();
    expect(under(), 0);
  });
}

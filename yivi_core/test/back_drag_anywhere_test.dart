// The back swipe starts anywhere on a pushed page, not only at the screen's
// edge, as in a sheet's pages: on iOS and Android, on the router's pages on a
// phone and on a step stacked in a sheet on a tablet. What is on the page
// takes a horizontal drag first.

import "package:flutter/foundation.dart" show defaultTargetPlatform;
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/routing/adaptive_page.dart";
import "package:yivi_core/src/theme/back_swipe_transitions.dart";
import "package:yivi_core/src/theme/page_transitions.dart";

/// The navigator of the test that runs; a new one per test.
late GlobalKey<NavigatorState> _navigator;

Future<void> _pumpApp(WidgetTester tester, TargetPlatform platform) async {
  _navigator = GlobalKey<NavigatorState>();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: _navigator,
      theme: ThemeData(
        platform: platform,
        pageTransitionsTheme: yiviPageTransitionsTheme,
      ),
      home: const Scaffold(body: Center(child: Text("first"))),
    ),
  );
}

Future<void> _push(WidgetTester tester, Route<void> route) async {
  _navigator.currentState!.push(route);
  await tester.pumpAndSettle();
}

MaterialPageRoute<void> _page(Widget body) =>
    MaterialPageRoute<void>(builder: (_) => Scaffold(body: body));

/// A drag from the middle of the page, [dx] to the right.
Future<void> _dragFromMiddle(WidgetTester tester, double dx) async {
  final gesture = await tester.startGesture(const Offset(200, 400));
  await gesture.moveBy(Offset(dx / 2, 0));
  await gesture.moveBy(Offset(dx / 2, 0));
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  final bothPlatforms = TargetPlatformVariant({
    TargetPlatform.iOS,
    TargetPlatform.android,
  });

  testWidgets("a drag from the middle of a page takes it back", (tester) async {
    await _pumpApp(tester, defaultTargetPlatform);
    await _push(tester, _page(const Center(child: Text("second"))));

    await _dragFromMiddle(tester, 300);

    expect(find.text("first"), findsOneWidget);
    expect(find.text("second"), findsNothing);
  }, variant: bothPlatforms);

  testWidgets("a short drag from the middle leaves the page where it was", (
    tester,
  ) async {
    await _pumpApp(tester, defaultTargetPlatform);
    await _push(tester, _page(const Center(child: Text("second"))));

    await _dragFromMiddle(tester, 60);

    expect(find.text("second"), findsOneWidget);
    expect(tester.getCenter(find.text("second")).dx, 200);
  }, variant: bothPlatforms);

  testWidgets("a drag the other way only holds the page in place", (
    tester,
  ) async {
    await _pumpApp(tester, TargetPlatform.iOS);
    await _push(tester, _page(const Center(child: Text("second"))));

    await _dragFromMiddle(tester, -300);

    expect(find.text("second"), findsOneWidget);
    expect(tester.getCenter(find.text("second")).dx, 200);
  });

  testWidgets("a list that scrolls sideways keeps its drag", (tester) async {
    await _pumpApp(tester, TargetPlatform.iOS);
    final controller = ScrollController(initialScrollOffset: 400);
    addTearDown(controller.dispose);
    await _push(
      tester,
      _page(
        Column(
          children: [
            const Text("second"),
            Expanded(
              child: ListView(
                controller: controller,
                scrollDirection: Axis.horizontal,
                children: [
                  for (var i = 0; i < 10; i++)
                    SizedBox(width: 200, child: Text("item $i")),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    await _dragFromMiddle(tester, 300);

    expect(find.text("second"), findsOneWidget);
    expect(controller.offset, lessThan(400));
  });

  testWidgets("the first page claims no drag: a list on it scrolls", (
    tester,
  ) async {
    await _pumpApp(tester, TargetPlatform.iOS);
    await _dragFromMiddle(tester, 300);
    expect(find.text("first"), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BackDragDetector),
        matching: find.byWidgetPredicate(
          (w) => w is GestureDetector && w.onHorizontalDragStart != null,
        ),
      ),
      findsNothing,
    );
  });

  testWidgets("a router page pushed on a phone is taken back from the middle", (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: "/",
          builder: (_, _) => const Scaffold(body: Center(child: Text("home"))),
          routes: [
            GoRoute(
              path: "settings",
              pageBuilder: (_, state) => AdaptivePage<void>(
                key: state.pageKey,
                name: state.uri.path,
                child: const Scaffold(body: Center(child: Text("settings"))),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: ThemeData(
          platform: TargetPlatform.iOS,
          pageTransitionsTheme: yiviPageTransitionsTheme,
        ),
        routerConfig: router,
      ),
    );
    router.push("/settings");
    await tester.pumpAndSettle();

    await _dragFromMiddle(tester, 300);

    expect(find.text("settings"), findsNothing);
    expect(find.text("home"), findsOneWidget);
  });

  testWidgets("a step stacked in a sheet on a tablet is taken back from "
      "anywhere in the sheet", (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1180, 820);
    addTearDown(tester.view.reset);
    Page<void> sheet(GoRouterState state, String text) => AdaptivePage<void>(
      key: state.pageKey,
      name: state.uri.path,
      child: Scaffold(body: Center(child: Text(text))),
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: "/",
          builder: (_, _) => const Scaffold(body: Center(child: Text("home"))),
          routes: [
            GoRoute(
              path: "settings",
              pageBuilder: (_, state) => sheet(state, "settings"),
              routes: [
                GoRoute(
                  path: "language",
                  pageBuilder: (_, state) => sheet(state, "language"),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: ThemeData(
          platform: TargetPlatform.iOS,
          pageTransitionsTheme: yiviPageTransitionsTheme,
        ),
        routerConfig: router,
      ),
    );
    router.push("/settings");
    await tester.pumpAndSettle();
    router.push("/settings/language");
    await tester.pumpAndSettle();
    expect(find.text("language"), findsOneWidget);

    // Halfway through, the step has moved with the finger inside the sheet,
    // and the step under it is in view.
    final center = tester.getCenter(find.text("language"));
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(100, 0));
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();
    expect(tester.getCenter(find.text("language")).dx, greaterThan(center.dx));
    expect(find.text("settings"), findsOneWidget);
    await gesture.moveBy(const Offset(250, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text("language"), findsNothing);
    expect(find.text("settings"), findsOneWidget);
  });
}

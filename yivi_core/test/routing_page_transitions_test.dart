import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

// Flutter 3.47 unbundled the Material library and the app root became a
// material_ui MaterialApp. go_router picks the Page type for a GoRoute
// `builder:` by looking up the MaterialApp/CupertinoApp ancestor *by exact
// type*; a go_router that still checks against the core SDK types finds
// neither and silently falls back to its WidgetsApp configuration, building
// every route as a NoTransitionPage: no page transitions on any platform and
// no iOS back-swipe. go_router 18 migrated the check to material_ui.

/// The router shape the app uses: plain `builder:` routes, so the Page type
/// is chosen by go_router's app-type detection.
GoRouter _router() => GoRouter(
  routes: [
    GoRoute(
      path: "/",
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text("first"))),
    ),
    GoRoute(
      path: "/second",
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text("second"))),
    ),
  ],
);

void main() {
  testWidgets(
    "routes built by a material_ui MaterialApp get a real transition",
    (tester) async {
      final router = _router();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      router.go("/second");
      await tester.pumpAndSettle();

      final route = ModalRoute.of(tester.element(find.text("second")))!;
      expect(
        route.transitionDuration,
        greaterThan(Duration.zero),
        reason:
            "go_router fell back to NoTransitionPage, so it did not recognise "
            "the material_ui MaterialApp as a Material app",
      );
    },
  );

  testWidgets("edge swipe pops the route on iOS", (tester) async {
    final router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.push("/second");
    await tester.pumpAndSettle();
    expect(find.text("second"), findsOneWidget);

    final gesture = await tester.startGesture(const Offset(5.0, 300.0));
    await gesture.moveBy(const Offset(400.0, 0.0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text("first"), findsOneWidget);
    expect(find.text("second"), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}

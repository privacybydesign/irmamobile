import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/util/navigation.dart";

/// Tracks the live route stack so tests can assert on it directly, rather than
/// inferring it from whichever screen happens to be visible.
class _StackObserver extends NavigatorObserver {
  final _routes = <Route<dynamic>>[];

  List<String?> get names => _routes.map((r) => r.settings.name).toList();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _routes.add(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _routes.remove(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _routes.remove(route);
}

void main() {
  /// Pumps a navigator holding [names] as its stack, bottom-to-top. Each route
  /// renders its own name, so `tester.element(find.text(name))` yields a
  /// context below the navigator to call the extension on.
  ///
  /// The initial route is generated explicitly: the default initial-route
  /// generator splits a path like `/home/add_data` into one route per segment,
  /// which would seed the stack with routes the test never asked for.
  Future<_StackObserver> pumpStack(
    WidgetTester tester,
    List<String> names,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final observer = _StackObserver();
    Route<dynamic> build(RouteSettings settings) => MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => Scaffold(body: Text(settings.name!)),
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [observer],
        onGenerateInitialRoutes: (_) => [
          build(RouteSettings(name: names.first)),
        ],
        onGenerateRoute: build,
      ),
    );
    for (final name in names.skip(1)) {
      navigatorKey.currentState!.pushNamed(name);
      await tester.pumpAndSettle();
    }

    expect(observer.names, names, reason: "stack setup");
    return observer;
  }

  Future<void> popToUnderlyingSessionFrom(
    WidgetTester tester,
    String topRoute,
  ) async {
    tester.element(find.text(topRoute)).popToUnderlyingSession();
    await tester.pumpAndSettle();
  }

  testWidgets("pops back to the session directly below", (tester) async {
    final observer = await pumpStack(tester, [
      "/home",
      "/session?session_id=1",
      "/session?session_id=2",
      "/error",
    ]);

    await popToUnderlyingSessionFrom(tester, "/error");

    // Matched on the path prefix, so the query params do not get in the way.
    expect(observer.names, [
      "/home",
      "/session?session_id=1",
      "/session?session_id=2",
    ]);
  });

  testWidgets("pops past the current session to the one below", (tester) async {
    final observer = await pumpStack(tester, [
      "/home",
      "/session?session_id=1",
      "/session?session_id=2",
    ]);

    await popToUnderlyingSessionFrom(tester, "/session?session_id=2");

    expect(observer.names, ["/home", "/session?session_id=1"]);
  });

  // Regression: callers decide there is an underlying session from repository
  // state, which can disagree with the stack (a stale session stuck in
  // requestPermission is enough). This used to pop every page and trip
  // go_router's "you have popped the last page off of the stack" assertion,
  // corrupting the widget tree for the rest of the process.
  testWidgets("stops at the first route when no session is below", (
    tester,
  ) async {
    final observer = await pumpStack(tester, [
      "/home",
      "/home/add_data",
      "/error",
    ]);

    await popToUnderlyingSessionFrom(tester, "/error");

    expect(observer.names, ["/home"]);
    expect(find.text("/home"), findsOneWidget);
  });

  testWidgets("leaves a single-route stack alone", (tester) async {
    final observer = await pumpStack(tester, ["/home"]);

    await popToUnderlyingSessionFrom(tester, "/home");

    expect(observer.names, ["/home"]);
    expect(find.text("/home"), findsOneWidget);
  });

  testWidgets("keeps a session that is the only route on the stack", (
    tester,
  ) async {
    final observer = await pumpStack(tester, ["/session?session_id=1"]);

    await popToUnderlyingSessionFrom(tester, "/session?session_id=1");

    expect(observer.names, ["/session?session_id=1"]);
  });
}

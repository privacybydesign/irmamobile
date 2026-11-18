import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/routing.dart";
import "package:yivi_core/src/data/browser.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/data/issuance_launcher.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/session_state.dart";
import "package:yivi_core/src/models/session_user_interaction.dart";
import "package:yivi_core/src/providers/credential_store_provider.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/wallet_cards_provider.dart";
import "package:yivi_core/src/routing/navigation.dart";
import "package:yivi_core/src/screens/session/result/done_flight.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/flight/flight.dart";
import "package:yivi_core/src/widgets/layout/legacy_material_bridge.dart";

import "onboarding_v2_harness.dart";
import "pump_translated.dart";

/// A browser whose ways out of the app are recorded instead of taken:
/// opening a URL and the OpenID4VCI browser login.
class RecordingBrowser extends Browser {
  RecordingBrowser(super.sessions);

  /// Each URL opened, whether in the in-app browser, and the router's
  /// location at that moment.
  final opened = <({String url, bool inApp, String at})>[];

  /// The router's location now (set by [pumpSessionScreen]).
  String Function() location = () => "";

  /// The authorization URLs handed to the browser login.
  final authorizations = <String>[];

  /// Set to make opening a URL fail, as when no app takes it.
  Object? openFails;

  Future<void> _open(String url, {required bool inApp}) async {
    opened.add((url: url, inApp: inApp, at: location()));
    if (openFails case final error?) throw error;
  }

  @override
  Future<void> openExternally(String url) => _open(url, inApp: false);

  @override
  Future<void> openInApp(String url) => _open(url, inApp: true);

  @override
  Future<void> authenticateOpenID4VCI(String authorizationRequestUrl) async =>
      authorizations.add(authorizationRequestUrl);
}

/// Keeps the routes on the stack, by name, bottom first.
class StackObserver extends NavigatorObserver {
  final _routes = <Route<dynamic>>[];

  /// How many routes were popped.
  var pops = 0;

  List<String?> get names => [for (final r in _routes) r.settings.name];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _routes.add(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
    _routes.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _routes.remove(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (i >= 0 && newRoute != null) _routes[i] = newRoute;
  }
}

class _NoWallet extends CredentialOrderController {
  @override
  Future<List<Credential>> build() async => const [];
}

/// A [SessionScreen] in a small app, with Go played by the test.
class SessionHarness {
  SessionHarness._(
    this.bridge,
    this.repo,
    this.browser,
    this.router,
    this.observer,
    this._container,
  );

  final RecordingBridge bridge;
  final IrmaRepository repo;
  final RecordingBrowser browser;
  final GoRouter router;
  final StackObserver observer;

  final ProviderContainer Function() _container;

  /// Which cards were launched in the app, for the finish.
  IssuanceLauncher get launcher => _container().read(issuanceLauncherProvider);

  /// Sends [state] to the app, as Go does.
  void emit(SessionState state) =>
      repo.dispatch(SessionStateEvent(sessionState: state));

  /// What the app asked Go to do with its sessions.
  List<SessionUserInteractionEvent> get interactions =>
      bridge.dispatched.whereType<SessionUserInteractionEvent>().toList();

  /// The interactions of one [type].
  List<SessionUserInteractionEvent> of(UserInteractionType type) => [
    for (final e in interactions)
      if (e.type == type) e,
  ];

  /// Everything the app sent Go of type [T].
  List<T> sent<T extends Event>() => bridge.dispatched.whereType<T>().toList();
}

/// The route of [sessionId] as the app names it.
String sessionLocation(int sessionId, {bool hasUnderlyingSession = false}) =>
    Uri(
      path: "/session",
      queryParameters: SessionRouteParams(
        sessionId: sessionId,
        hasUnderlyingSession: hasUnderlyingSession,
      ).toQueryParams(),
    ).toString();

/// Home ("home"), with [SessionScreen] for [sessionId] pushed on it. With
/// [underlyingId] a request's page ("request") lies between, at a
/// `/session` route as in the app, and the session is nested on it.
Future<SessionHarness> pumpSessionScreen(
  WidgetTester tester, {
  required int sessionId,
  int? underlyingId,
  List<Override> overrides = const [],
  Size size = const Size(390, 844),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  addTearDown(Flight.reset);
  addTearDown(DoneFlight.reset);
  final bridge = RecordingBridge();
  final repo = (await tester.runAsync(() async {
    final preferences = await freshPreferences();
    return IrmaRepository(client: bridge, preferences: preferences);
  }))!;
  final browser = RecordingBrowser(repo.sessions);
  addTearDown(() => tester.runAsync(repo.close));
  final observer = StackObserver();
  final router = GoRouter(
    initialLocation: "/home",
    observers: [observer],
    routes: [
      GoRoute(
        path: "/home",
        builder: (_, _) => const Scaffold(body: Center(child: Text("home"))),
      ),
      GoRoute(
        path: "/session",
        builder: (_, state) {
          final params = SessionRouteParams.fromQueryParams(
            state.uri.queryParameters,
          );
          if (params.sessionId == underlyingId) {
            return const Scaffold(body: Center(child: Text("request")));
          }
          return SessionScreen(
            sessionId: params.sessionId,
            hasUnderlyingSession: params.hasUnderlyingSession,
          );
        },
      ),
    ],
  );
  addTearDown(router.dispose);
  browser.location = () =>
      router.routerDelegate.currentConfiguration.last.matchedLocation;
  await pumpTranslated(
    tester,
    ProviderScope(
      overrides: [
        irmaRepositoryProvider.overrideWithValue(repo),
        preferencesProvider.overrideWithValue(repo.preferences),
        browserProvider.overrideWithValue(browser),
        routerProvider.overrideWithValue(router),
        credentialOrderControllerProvider.overrideWith(_NoWallet.new),
        groupedCredentialStoreProvider.overrideWith(
          (ref) => Stream.value(const []),
        ),
        ...overrides,
      ],
      child: IrmaTheme(
        builder: (_) => MaterialApp.router(
          routerConfig: router,
          builder: (context, child) =>
              LegacyMaterialBridge(child: child ?? const SizedBox.shrink()),
          localizationsDelegates: [
            FlutterI18nDelegate(
              translationLoader: FileTranslationLoader(
                basePath: "assets/locales",
                forcedLocale: const Locale("en", "US"),
              ),
            ),
            ...GlobalMaterialLocalizations.delegates,
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (underlyingId != null) {
    unawaitedPush(router, sessionLocation(underlyingId));
    await pumpFrames(tester);
  }
  unawaitedPush(
    router,
    sessionLocation(sessionId, hasUnderlyingSession: underlyingId != null),
  );
  await pumpFrames(tester);
  return SessionHarness._(
    bridge,
    repo,
    browser,
    router,
    observer,
    () => ProviderScope.containerOf(
      tester.element(find.byType(IrmaTheme)),
      listen: false,
    ),
  );
}

/// Pushes [location] without waiting for its result.
void unawaitedPush(GoRouter router, String location) {
  router.push<void>(location).ignore();
}

/// Pumps frames for [duration], 50 ms apart, letting the repository's
/// streams deliver in between: they run on the real event loop, not the
/// test's fake clock. A spinner never settles, so this stands in for
/// pumpAndSettle.
Future<void> pumpFrames(
  WidgetTester tester, [
  Duration duration = const Duration(seconds: 1),
]) async {
  for (
    var t = Duration.zero;
    t < duration;
    t += const Duration(milliseconds: 50)
  ) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

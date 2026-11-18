import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "src/providers/pane_selection_provider.dart";
import "src/providers/preferences_provider.dart";
import "src/providers/redirect_state_provider.dart";
import "src/providers/rooted_device_detector_provider.dart";
import "src/screens/activity/activity_detail_screen.dart";
import "src/screens/back_to_website/back_to_website_screen.dart";
import "src/screens/change_language/change_language_screen.dart";
import "src/screens/change_pin/change_pin_screen.dart";
import "src/screens/data/credential_detail/credential_detail_screen.dart";
import "src/screens/data/wallet/wallet_transition.dart";
import "src/screens/debug/debug_screen.dart";
import "src/screens/enrollment/enrollment_screen.dart";
import "src/screens/error/error_screen.dart";
import "src/screens/help/help_screen.dart";
import "src/screens/home/home_screen.dart";
import "src/screens/home/pane_handoffs.dart";
import "src/screens/loading/loading_screen.dart";
import "src/screens/name_changed/name_changed_screen.dart";
import "src/screens/required_update/required_update_screen.dart";
import "src/screens/reset_pin/reset_pin_screen.dart";
import "src/screens/rooted_warning/repository.dart";
import "src/screens/rooted_warning/rooted_warning_screen.dart";
import "src/screens/session/session_screen.dart";
import "src/screens/settings/settings_screen.dart";
import "src/util/navigation.dart";
import "src/widgets/adaptive_page.dart";

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

/// A route whose screen is presented by [mode] on tablets and comes in with
/// [phone] on phones (see [AdaptivePage]).
GoRoute _adaptive({
  required PresentationMode mode,
  PhoneTransition phone = PhoneTransition.push,
  required String path,
  required GoRouterWidgetBuilder builder,
  List<RouteBase> routes = const [],
}) => GoRoute(
  path: path,
  routes: routes,
  pageBuilder: (context, state) => AdaptivePage<void>(
    key: state.pageKey,
    name: state.uri.path,
    mode: mode,
    phoneTransition: phone,
    child: builder(context, state),
  ),
);

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// The app's router. It goes where [redirectStateProvider] says, again on
/// every change of it.
final routerProvider = Provider<GoRouter>((ref) {
  final redirectState = ValueNotifier(RedirectState.initial);
  ref.listen(redirectStateProvider, (_, next) {
    if (next.value case final state?) redirectState.value = state;
  });
  final router = _createRouter(ref, redirectState);
  ref.onDispose(() {
    router.dispose();
    redirectState.dispose();
  });
  return router;
});

GoRouter _createRouter(Ref ref, ValueListenable<RedirectState> redirectState) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    observers: [routeObserver],
    initialLocation: "/loading",
    refreshListenable: redirectState,
    errorBuilder: (context, state) => RouteNotFoundScreen(),
    routes: [
      _adaptive(
        mode: PresentationMode.sheet,
        path: "/error",
        builder: (context, state) => ErrorScreen(
          details: ErrorRouteArgs.fromState(state).message,
          onTapClose: context.pop,
        ),
      ),
      GoRoute(
        path: "/loading",
        pageBuilder: (context, state) =>
            NoTransitionPage(name: "/loading", child: LoadingScreen()),
      ),
      _adaptive(
        mode: PresentationMode.full,
        path: "/reset_pin",
        builder: (context, state) => ResetPinScreen(),
      ),
      // Not under /home/settings: the screen has a navigator of its own.
      _adaptive(
        mode: PresentationMode.sheet,
        path: "/change_pin",
        builder: (context, state) => ChangePinScreen(),
      ),
      // The enrollment lays itself out for every size (two columns when the
      // window is wider than high), so it gets the whole window.
      _adaptive(
        mode: PresentationMode.window,
        path: "/enrollment",
        builder: (context, state) => EnrollmentScreen(),
      ),
      _adaptive(
        mode: PresentationMode.sheet,
        path: "/back_to_website",
        builder: (context, state) => const BackToWebsiteScreen(),
      ),
      GoRoute(
        path: "/home",
        pageBuilder: (context, state) {
          final instant =
              TransitionStyleProvider.shouldPerformInstantTransitionToHome(
                context,
              );
          if (instant) {
            TransitionStyleProvider.resetInstantTransitionToHomeMark(context);
          }
          return _HomePage(
            key: state.pageKey,
            instant: instant,
            child: HomeScreen(),
          );
        },
        routes: [
          GoRoute(
            path: "credential",
            // Moves the data tab's items out of the way while the card
            // flies (see WalletTransition).
            pageBuilder: (context, state) {
              final args = CredentialRouteArgs.fromState(state);
              return WalletDetailPage(
                key: state.pageKey,
                name: "/home/credential",
                // Turned sideways, the card moves into the tab's detail pane.
                child: cardHandoff(
                  context,
                  args.hash,
                  CredentialDetailScreen(hash: args.hash, found: args.found),
                ),
              );
            },
          ),
          // An ordinary page, pushed from the side. On tablets the details
          // show in the pane instead.
          _adaptive(
            mode: PresentationMode.full,
            path: "activity_details",
            builder: (context, state) {
              final log = ActivityRouteArgs.fromState(state).log;
              return activityHandoff(
                context,
                log,
                ActivityDetailsScreen(
                  args: ActivityDetailsScreenArgs(logEntry: log),
                ),
              );
            },
          ),
          _adaptive(
            mode: PresentationMode.sheet,
            path: "help",
            builder: (context, state) =>
                morePageHandoff(context, MorePage.faq, const HelpScreen()),
          ),
          _adaptive(
            mode: PresentationMode.sheet,
            path: "debug",
            builder: (context, state) => const DebugScreen(),
          ),
          _adaptive(
            mode: PresentationMode.sheet,
            path: "settings",
            builder: (context, state) => morePageHandoff(
              context,
              MorePage.settings,
              const SettingsScreen(),
            ),
            routes: [
              _adaptive(
                mode: PresentationMode.sheet,
                path: "change_language",
                builder: (context, state) => ChangeLanguageScreen(),
              ),
            ],
          ),
        ],
      ),
      _adaptive(
        mode: PresentationMode.window,
        phone: PhoneTransition.rise,
        path: "/session",
        builder: (context, state) {
          final args = SessionRouteParams.fromState(state);
          return SessionScreen(
            sessionId: args.sessionId,
            hasUnderlyingSession: args.hasUnderlyingSession,
          );
        },
      ),
      _adaptive(
        mode: PresentationMode.full,
        path: "/rooted_warning",
        builder: (context, state) {
          return RootedWarningScreen(
            onAcceptRiskButtonPressed: () {
              DetectRootedDeviceIrmaPrefsRepository(
                preferences: ref.read(preferencesProvider),
                detector: ref.read(rootedDeviceDetectorProvider),
              ).setHasAcceptedRootedDeviceRisk();
            },
          );
        },
      ),
      _adaptive(
        mode: PresentationMode.full,
        path: "/name_changed",
        builder: (context, state) {
          return NameChangedScreen(
            onContinuePressed: () => ref
                .read(preferencesProvider)
                .showNameChangedNotification
                .set(false),
          );
        },
      ),
      _adaptive(
        mode: PresentationMode.full,
        path: "/update_required",
        builder: (context, state) => RequiredUpdateScreen(),
      ),
    ],
    redirect: (context, state) => redirectState.value.redirect(),
  );
}

class RouteNotFoundScreen extends StatelessWidget {
  const RouteNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      throw Exception(
        "Route not found. Invalid route or invalid arguments were specified.",
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Page not found")),
      body: const Center(child: Text("")),
    );
  }
}

/// The home page: comes in at once ([instant], after loading, a PIN
/// change or an issuance) or pushed. One kind of page either way, so that
/// building it again (a card opened over it) updates the route home is in
/// instead of replacing it, which would build home anew with its lists back
/// at the top.
class _HomePage extends MaterialPage<void> {
  final bool instant;

  const _HomePage({
    required super.key,
    required this.instant,
    required super.child,
  }) : super(name: "/home");

  @override
  Route<void> createRoute(BuildContext context) => instant
      ? PageRouteBuilder<void>(
          settings: this,
          pageBuilder: (_, _, _) => child,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        )
      : super.createRoute(context);
}

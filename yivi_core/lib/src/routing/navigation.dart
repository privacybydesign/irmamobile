import "package:flutter/widgets.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "../models/log_entry.dart";

extension RoutingHelpers on BuildContext {
  void pushErrorScreen({required String message}) {
    final args = ErrorRouteArgs(message);
    push(args.location, extra: args.extra);
  }

  void pushReplacementErrorScreen({required String message}) {
    final args = ErrorRouteArgs(message);
    pushReplacement(args.location, extra: args.extra);
  }

  void pushResetPinScreen() {
    push("/reset_pin");
  }

  /// Pops back to the nearest session screen below the current one.
  ///
  /// Treats the first route as a floor, so it can never empty the navigator.
  /// Callers decide there is an underlying session from repository state
  /// (`hasActiveSessions`), which can disagree with the actual stack — a stale
  /// session left in `requestPermission` is enough. Without the floor, that
  /// mismatch pops every page and trips go_router's "you have popped the last
  /// page off of the stack" assertion, which corrupts the widget tree for good.
  /// Landing on the first route instead matches what
  /// [popToUnderlyingSessionOrHome] would have done without an underlying
  /// session.
  void popToUnderlyingSession() {
    final navigator = Navigator.of(this);
    // We have to at least do one pop in case the current screen is already a
    // session — unless it is the only screen left.
    if (!navigator.canPop()) return;
    navigator.pop();
    navigator.popUntil((route) {
      if (route.isFirst) return true;
      final name = route.settings.name;
      // GoRouter sets the route name to the full URI (including query params),
      // so we match on the path prefix rather than an exact name.
      return name != null && name.startsWith("/session");
    });
  }

  void popToUnderlyingSessionOrHome({required bool hasUnderlyingSession}) {
    if (hasUnderlyingSession) {
      popToUnderlyingSession();
    } else {
      goHomeScreen();
    }
  }

  void goHomeScreenWithoutTransition() {
    TransitionStyleProvider.performInstantTransitionToHomeScreen(this);
  }

  void goHomeScreen() {
    go("/home");
  }

  void goSettingsScreen() {
    go("/home/settings");
  }

  void goHelpScreen() {
    go("/home/help");
  }

  void goDebugScreen() {
    go("/home/debug");
  }

  void goEnrollmentScreen() {
    go("/enrollment");
  }

  void pushBackToWebsiteScreen() {
    push("/back_to_website");
  }

  void pushLanguageSettingsScreen() {
    push("/home/settings/change_language");
  }

  void pushChangePinScreen() {
    push("/change_pin");
  }

  void pushActivityDetailsScreen({required LogInfo logInfo}) {
    final args = ActivityRouteArgs(logInfo);
    push(args.location, extra: args.extra);
  }

  /// Opens the full-screen detail view of one card (credential instance).
  /// Call [WalletTransition.begin] first when it opens from a card on screen.
  /// [found]: the field (a claim path key) a search found the card by; the
  /// card opens on it.
  void pushCredentialDetailScreen(String hash, {String? found}) {
    push(CredentialRouteArgs(hash, found: found).location);
  }

  void pushReplacementSessionScreen(SessionRouteParams args) {
    pushReplacement(args.location);
  }

  void pushSessionScreen(SessionRouteParams args) {
    push(args.location);
  }
}

// Each route that takes arguments has one class for them: [location] (and
// for an object, [extra]) to go there, `fromState` to read them back in the
// route's builder.

/// `/session`: the session to show, in the query.
class SessionRouteParams {
  final int sessionId;
  final bool hasUnderlyingSession;

  SessionRouteParams({
    required this.sessionId,
    this.hasUnderlyingSession = false,
  });

  Map<String, String> toQueryParams() {
    return {
      "session_id": "$sessionId",
      if (hasUnderlyingSession) "has_underlying_session": "true",
    };
  }

  static SessionRouteParams fromQueryParams(Map<String, String> params) {
    return SessionRouteParams(
      sessionId: int.parse(params["session_id"]!),
      hasUnderlyingSession: params["has_underlying_session"] == "true",
    );
  }

  String get location =>
      Uri(path: "/session", queryParameters: toQueryParams()).toString();

  static SessionRouteParams fromState(GoRouterState state) =>
      fromQueryParams(state.uri.queryParameters);
}

/// `/home/credential`: the card (its hash) and the field a search found it
/// by, in the query.
class CredentialRouteArgs {
  final String hash;
  final String? found;

  const CredentialRouteArgs(this.hash, {this.found});

  String get location => Uri(
    path: "/home/credential",
    queryParameters: {"hash": hash, "found": ?found},
  ).toString();

  static CredentialRouteArgs fromState(GoRouterState state) =>
      CredentialRouteArgs(
        state.uri.queryParameters["hash"] ?? "",
        found: state.uri.queryParameters["found"],
      );
}

/// `/error`: the message to show, carried as the route's extra.
class ErrorRouteArgs {
  final String message;

  const ErrorRouteArgs(this.message);

  String get location => "/error";
  Object get extra => message;

  static ErrorRouteArgs fromState(GoRouterState state) =>
      ErrorRouteArgs(state.extra as String);
}

/// `/home/activity_details`: the log entry to show, carried as the route's
/// extra (there is no way to look one up by id).
class ActivityRouteArgs {
  final LogInfo log;

  const ActivityRouteArgs(this.log);

  String get location => "/home/activity_details";
  Object get extra => log;

  static ActivityRouteArgs fromState(GoRouterState state) =>
      ActivityRouteArgs(state.extra as LogInfo);
}

// =============================================================================================

/// The transition to the home page should be instant in some cases and
/// "normal" in other cases. For example coming from the pin screen should be an instant transition,
/// while coming back from the add_data page should be a native sliding transition.
/// This is a hard problem, as during page building in GoRouter there is no way to detect whether
/// you're coming from a subpage or not. Passing parameters together with the context.go() call also doesn't
/// work as it remembers the parameters passed to the initial transition, so coming back from a subpage still has the
/// parameters from coming from the pin screen.
/// The (kind of hacky, ugly) solution we made up for this is to set a flag when going to the home screen
/// and resetting it when the home screen is built. This way we only have the instant transition once and
/// normal transitions for all subsequent navigation actions.
class TransitionStyleProvider extends StatefulWidget {
  final Widget child;

  const TransitionStyleProvider({required this.child});

  static void performInstantTransitionToHomeScreen(BuildContext context) {
    final state = context
        .findAncestorStateOfType<TransitionStyleProviderState>();
    // Without the provider (e.g. in a test) home opens as usual.
    state?._shouldPerformInstantTransitionToHomeScreen = true;
    context.goHomeScreen();
  }

  static bool shouldPerformInstantTransitionToHome(BuildContext context) {
    final state = context
        .findAncestorStateOfType<TransitionStyleProviderState>();
    return state?._shouldPerformInstantTransitionToHomeScreen ?? false;
  }

  static void resetInstantTransitionToHomeMark(BuildContext context) {
    final state = context
        .findAncestorStateOfType<TransitionStyleProviderState>();
    state?._shouldPerformInstantTransitionToHomeScreen = false;
  }

  @override
  State<StatefulWidget> createState() {
    return TransitionStyleProviderState();
  }
}

class TransitionStyleProviderState extends State<TransitionStyleProvider> {
  bool _shouldPerformInstantTransitionToHomeScreen = false;

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

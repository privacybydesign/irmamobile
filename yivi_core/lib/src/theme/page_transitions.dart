import "package:cupertino_ui/cupertino_ui.dart"
    show CupertinoPageTransitionsBuilder;
import "package:material_ui/material_ui.dart";

/// Wraps the platform's page transitions so that "Reduce motion" turns every
/// push into a cross-fade.
class YiviPageTransitionsBuilder extends PageTransitionsBuilder {
  final PageTransitionsBuilder platform;

  const YiviPageTransitionsBuilder(this.platform);

  @override
  Duration get transitionDuration => platform.transitionDuration;

  @override
  Duration get reverseTransitionDuration => platform.reverseTransitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      platform.delegatedTransition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    return platform.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

/// The platform's own transitions, each wrapped in
/// [YiviPageTransitionsBuilder].
const yiviPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: YiviPageTransitionsBuilder(
      PredictiveBackPageTransitionsBuilder(),
    ),
    TargetPlatform.iOS: YiviPageTransitionsBuilder(
      CupertinoPageTransitionsBuilder(),
    ),
    TargetPlatform.macOS: YiviPageTransitionsBuilder(
      CupertinoPageTransitionsBuilder(),
    ),
    TargetPlatform.linux: YiviPageTransitionsBuilder(
      ZoomPageTransitionsBuilder(),
    ),
    TargetPlatform.windows: YiviPageTransitionsBuilder(
      ZoomPageTransitionsBuilder(),
    ),
    TargetPlatform.fuchsia: YiviPageTransitionsBuilder(
      ZoomPageTransitionsBuilder(),
    ),
  },
);

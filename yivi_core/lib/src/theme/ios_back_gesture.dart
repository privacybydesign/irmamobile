import "dart:math";

import "package:cupertino_ui/cupertino_ui.dart"
    show
        CupertinoFullscreenDialogTransition,
        CupertinoPageTransition,
        CupertinoPageTransitionsBuilder;
import "package:flutter/gestures.dart" show HorizontalDragGestureRecognizer;
import "package:flutter/physics.dart";
import "package:material_ui/material_ui.dart";

/// The iOS page transition ([CupertinoPageTransition]) with a back swipe
/// that finishes as on iOS.
///
/// Flutter's own swipe jumps when the finger lets go, twice over:
/// - it ends with a 350 ms [Curves.fastEaseInToSlowEaseOut] from where the
///   finger let go, which covers most of the way in the first few frames;
/// - the page under it (moved by [CupertinoPageTransition.delegatedTransition])
///   is on one curve while the swipe runs forward and on another once the
///   pop runs in reverse, so it snaps to a different place at the release.
///
/// Here the page goes on from the finger's position at the finger's speed
/// and slows down to its end on a spring that does not bounce, and the page
/// under it follows that, linearly, until the swipe is done.
class YiviCupertinoPageTransitionsBuilder extends PageTransitionsBuilder {
  const YiviCupertinoPageTransitionsBuilder();

  static const _platform = CupertinoPageTransitionsBuilder();

  @override
  Duration get transitionDuration => _platform.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _platform.reverseTransitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => _under;

  /// The page under this one: a third of the way off to the left at the
  /// end, as on iOS.
  static Widget? _under(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) => _UnderSlide(animation: secondaryAnimation, child: child);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // While a finger drags the page, it follows the finger exactly.
    final linear = route.popGestureInProgress;
    if (route.fullscreenDialog) {
      return CupertinoFullscreenDialogTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: linear,
        child: child,
      );
    }
    return CupertinoPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: linear,
      child: _BackSwipeDetector(route: route, child: child),
    );
  }
}

/// The page under a pushed page, slid a third of the way to the left as
/// [animation] goes to 1: on iOS's curves for a push or a pop by a button,
/// linearly while a back swipe moves the page above (its finger, then its
/// spring), so it never changes curve halfway.
class _UnderSlide extends StatelessWidget {
  final Animation<double> animation;
  final Widget? child;

  const _UnderSlide({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    final swiping = Navigator.of(context).userGestureInProgressNotifier;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatedBuilder(
      animation: Listenable.merge([animation, swiping]),
      child: child,
      builder: (context, child) {
        final v = animation.value;
        final t = swiping.value
            ? v
            : animation.status == AnimationStatus.reverse
            ? Curves.easeInToLinear.transform(v)
            : Curves.linearToEaseOut.transform(v);
        return FractionalTranslation(
          translation: Offset((rtl ? 1 : -1) / 3 * t, 0),
          transformHitTests: false,
          child: child,
        );
      },
    );
  }
}

/// How wide the strip at the leading edge is where a back swipe starts, as
/// on iOS (wider where a notch is).
const double _edgeWidth = 20;

class _BackSwipeDetector extends StatefulWidget {
  final PageRoute<dynamic> route;
  final Widget child;

  const _BackSwipeDetector({required this.route, required this.child});

  @override
  State<_BackSwipeDetector> createState() => _BackSwipeDetectorState();
}

class _BackSwipeDetectorState extends State<_BackSwipeDetector> {
  late final HorizontalDragGestureRecognizer _recognizer;
  _BackSwipe? _swipe;

  @override
  void initState() {
    super.initState();
    _recognizer = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = _onStart
      ..onUpdate = _onUpdate
      ..onEnd = _onEnd
      ..onCancel = _onCancel;
  }

  void _onStart(DragStartDetails details) {
    _swipe = _BackSwipe.start(widget.route);
  }

  void _onUpdate(DragUpdateDetails details) {
    _swipe?.update(_logical(details.primaryDelta! / context.size!.width));
  }

  void _onEnd(DragEndDetails details) {
    _swipe?.end(
      _logical(details.velocity.pixelsPerSecond.dx / context.size!.width),
    );
    _swipe = null;
  }

  void _onCancel() {
    _swipe?.end(0);
    _swipe = null;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    // Gone in the middle of a swipe: the navigator still thinks a finger
    // holds it.
    final swipe = _swipe;
    if (swipe != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (swipe.navigator.mounted) swipe.navigator.didStopUserGesture();
      });
    }
    super.dispose();
  }

  double _logical(double value) => switch (Directionality.of(context)) {
    TextDirection.rtl => -value,
    TextDirection.ltr => value,
  };

  @override
  Widget build(BuildContext context) {
    final edge = switch (Directionality.of(context)) {
      TextDirection.rtl => MediaQuery.paddingOf(context).right,
      TextDirection.ltr => MediaQuery.paddingOf(context).left,
    };
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        PositionedDirectional(
          start: 0,
          width: max(edge, _edgeWidth),
          top: 0,
          bottom: 0,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              if (widget.route.popGestureEnabled) _recognizer.addPointer(event);
            },
          ),
        ),
      ],
    );
  }
}

/// One back swipe: moves the route's animation with the finger, and when
/// the finger lets go, finishes it (closing the page) or takes it back.
class _BackSwipe {
  final PageRoute<dynamic> route;
  final NavigatorState navigator;
  final AnimationController controller;

  _BackSwipe._(this.route, this.navigator, this.controller) {
    navigator.didStartUserGesture();
  }

  factory _BackSwipe.start(PageRoute<dynamic> route) => _BackSwipe._(
    route,
    route.navigator!,
    // The route's own controller: what the platform's swipe drives too.
    // ignore: invalid_use_of_protected_member
    route.controller!,
  );

  /// Under the finger: the page follows it exactly.
  void update(double delta) => controller.value -= delta;

  /// A fling of at least a screen width a second decides; slower, whether
  /// the page is more than half gone.
  static const double _flingVelocity = 1;

  /// The spring the page finishes on: about as quick as iOS, and damped
  /// enough that it never runs past its end.
  static final _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 220,
    ratio: 1,
  );

  /// The finger let go at [velocity] (screen widths a second, positive
  /// towards closing).
  void end(double velocity) {
    final bool close;
    if (!route.isCurrent) {
      // Popped already (or something was pushed over it) during the swipe.
      close = !route.isActive;
    } else if (velocity.abs() >= _flingVelocity) {
      close = velocity > 0;
    } else {
      close = controller.value < 0.5;
    }
    // The page goes on as fast as the finger moved it, in the controller's
    // terms (1 is open).
    final simulation = _Landing(
      SpringSimulation(_spring, controller.value, close ? 0 : 1, -velocity)
        ..tolerance = const Tolerance(distance: 0.001, velocity: 0.01),
      close ? 0 : 1,
    );
    if (close) {
      if (route.isCurrent) navigator.pop();
      // The pop may have finished at once (already at its end).
      if (controller.isAnimating) controller.animateBackWith(simulation);
    } else {
      controller.animateWith(simulation);
    }
    if (controller.isAnimating) {
      // The transition stays linear until the page is done: it follows
      // the spring, not its own curve as well.
      late final AnimationStatusListener done;
      done = (status) {
        if (status.isAnimating) return;
        navigator.didStopUserGesture();
        controller.removeStatusListener(done);
      };
      controller.addStatusListener(done);
    } else {
      navigator.didStopUserGesture();
    }
  }
}

/// [spring], but exactly at [end] once it is done (a spring only comes
/// within its tolerance): the page lands on its place, not a hair off.
class _Landing extends Simulation {
  final Simulation spring;
  final double end;

  _Landing(this.spring, this.end) : super(tolerance: spring.tolerance);

  @override
  double x(double time) => spring.isDone(time) ? end : spring.x(time);

  @override
  double dx(double time) => spring.isDone(time) ? 0 : spring.dx(time);

  @override
  bool isDone(double time) => spring.isDone(time);
}

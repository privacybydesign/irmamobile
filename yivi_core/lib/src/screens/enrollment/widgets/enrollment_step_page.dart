import "package:material_ui/material_ui.dart";

import "../../../theme/back_swipe_transitions.dart";
import "../../../theme/yivi_motion.dart";

/// One step of the enrollment as a page of its own: it comes in on a shared
/// axis instead of the iOS push. Only the content changes. The old step
/// fades out moving 30 pt to the left, the new one fades in from 30 pt to
/// the right a moment later and eases into place, with no shadow and no
/// darkening. The bar and the buttons over the pages stay where they are.
/// Back is the mirror image, and the back swipe from anywhere on the page
/// drives it with the finger ([BackDragDetector]).
class EnrollmentStepPage extends Page<void> {
  final Widget child;

  const EnrollmentStepPage({super.key, required this.child});

  @override
  Route<void> createRoute(BuildContext context) => _StepRoute(this);
}

/// How long a step change takes: the old step out (the first 40 %), the new
/// one in from a little in (22 %) to the end.
const enrollmentStepDuration = Duration(milliseconds: 410);

class _StepRoute extends PageRoute<void> {
  _StepRoute(EnrollmentStepPage page) : super(settings: page);

  EnrollmentStepPage get _page => settings as EnrollmentStepPage;

  @override
  Duration get transitionDuration => enrollmentStepDuration;

  @override
  Duration get reverseTransitionDuration => enrollmentStepDuration;

  @override
  bool get opaque => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      nextRoute is _StepRoute;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) =>
      previousRoute is _StepRoute;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _page.child;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    return BackDragDetector(
      route: this,
      child: _SharedAxis(
        animation: animation,
        covered: secondaryAnimation,
        linear: popGestureInProgress,
        child: child,
      ),
    );
  }
}

class _SharedAxis extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> covered;
  final bool linear;
  final Widget child;

  const _SharedAxis({
    required this.animation,
    required this.covered,
    required this.linear,
    required this.child,
  });

  static const _shift = 30.0;
  static const _in = Interval(0.22, 1);
  static const _out = Interval(0, 0.4);

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatedBuilder(
      animation: Listenable.merge([animation, covered]),
      builder: (context, child) {
        // Under a finger the page follows it as it is; else on the curves.
        final inT = linear
            ? _in.transform(animation.value)
            : YiviMotion.ease.transform(_in.transform(animation.value));
        final outT = linear
            ? _out.transform(covered.value)
            : Curves.easeIn.transform(_out.transform(covered.value));
        final dx = (_shift * (1 - inT) - _shift * outT) * (rtl ? -1 : 1);
        return Opacity(
          opacity: (inT * (1 - outT)).clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(dx, 0), child: child),
        );
      },
      child: child,
    );
  }
}

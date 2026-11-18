import "package:material_ui/material_ui.dart";

import "../../theme/yivi_motion.dart";
import "../../util/test_detection.dart";

/// Plays once from 0 to 1 over [duration] after [delay], along [curve], and
/// builds with where it is ([t]). Sits at 1 when motion is reduced or
/// during integration tests. [child] is passed through, built once.
class Entrance extends StatelessWidget {
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Widget Function(BuildContext context, double t, Widget? child) builder;
  final Widget? child;

  const Entrance({
    super.key,
    required this.duration,
    this.delay = Duration.zero,
    this.curve = YiviMotion.ease,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (motionStill(context)) return builder(context, 1, child);
    final total = duration + delay;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      builder: (context, t, child) {
        final local = ((t - start) / (1 - start)).clamp(0.0, 1.0);
        return builder(context, curve.transform(local), child);
      },
      child: child,
    );
  }
}

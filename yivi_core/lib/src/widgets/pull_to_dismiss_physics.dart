import "package:material_ui/material_ui.dart";

/// Scroll physics for a page that is dismissed by pulling it down: at the
/// top, dragging down does not scroll but grows [pull] (while [canPull], e.g.
/// for a drag that started at the top), and dragging back up first takes the
/// pull away before the content scrolls again. Otherwise the platform's own
/// physics apply, with their stretch or bounce. On release with a pull,
/// [onRelease] gets the velocity and the content does not fling.
class PullToDismissPhysics extends ScrollPhysics {
  final ValueNotifier<double> pull;
  final bool Function() canPull;
  final ValueChanged<double> onRelease;

  const PullToDismissPhysics({
    required this.pull,
    required this.canPull,
    required this.onRelease,
    super.parent,
  });

  @override
  PullToDismissPhysics applyTo(ScrollPhysics? ancestor) => PullToDismissPhysics(
    pull: pull,
    canPull: canPull,
    onRelease: onRelease,
    parent: buildParent(ancestor),
  );

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    final atTop = position.pixels <= position.minScrollExtent;
    // A positive offset drags the content down.
    if (canPull() && (pull.value > 0 || (atTop && offset > 0))) {
      // Resists a little, like a rubber band.
      final delta = offset > 0 ? offset * 0.8 : offset;
      pull.value = (pull.value + delta).clamp(0.0, double.infinity);
      return 0;
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (pull.value > 0) {
      onRelease(velocity);
      return null;
    }
    return super.createBallisticSimulation(position, velocity);
  }

  // Pulling down at the top must reach applyPhysicsToUserOffset, not bounce.
  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true;
}

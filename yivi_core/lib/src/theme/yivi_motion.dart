import "package:flutter/animation.dart";

/// Easing curves by role.
class YiviMotion {
  YiviMotion._();

  /// Quick to start and long to settle: how the redesign's own pages, cards
  /// and pictures move into place.
  static const ease = Cubic(0.2, 0.8, 0.2, 1);

  /// Past the mark and back: the tab bar's lens moving to a tab, the QR
  /// scanner's check popping in.
  static const overshoot = Cubic(0.3, 1.4, 0.5, 1);
}

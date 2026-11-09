import "package:flutter/widgets.dart";

/// Easing curves by role.
class YiviMotion {
  YiviMotion._();

  /// Quick to start and long to settle: how the redesign's own pages, cards
  /// and pictures move into place.
  static const ease = Cubic(0.2, 0.8, 0.2, 1);

  /// Past the mark and back: the tab bar's lens moving to a tab, the QR
  /// scanner's check popping in.
  static const overshoot = Cubic(0.3, 1.4, 0.5, 1);

  /// How a card is carried: picked up, held and put down (each beat of a
  /// `YiviFlight` eases on its own).
  static const carry = Cubic(0.3, 0.7, 0.2, 1);

  /// Something leaving: a sheet going down, a panel folding away.
  static const leave = Cubic(0.4, 0, 0.6, 1);

  /// [duration], or none when the user asked for less motion.
  static Duration duration(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

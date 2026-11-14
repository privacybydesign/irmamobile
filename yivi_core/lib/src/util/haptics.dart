import "package:flutter/services.dart";

/// The app's haptic feedback, named after what happened. Each event keeps
/// one strength everywhere it is felt.
abstract final class Haptics {
  /// A key or a small button pressed: the PIN keypad, the PIN field's
  /// arrow and eye.
  static void key() => HapticFeedback.lightImpact();

  /// A choice changes: a tab under the finger, a toggle, a menu opening, a
  /// card passing a place while it is dragged.
  static void select() => HapticFeedback.selectionClick();

  /// A card is picked up to be dragged.
  static void pickUp() => HapticFeedback.mediumImpact();

  /// Cards land in a new order: a dragged card let go, an arrangement
  /// picked.
  static void drop() => HapticFeedback.mediumImpact();

  /// Something went through: a session done, a PIN accepted.
  static void success() => HapticFeedback.mediumImpact();

  /// Something went wrong: a wrong PIN, a block, a session error.
  static void error() => HapticFeedback.heavyImpact();

  /// A QR code was read.
  static void scanned() => HapticFeedback.vibrate();
}

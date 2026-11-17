import "package:flutter/foundation.dart";

/// What a PIN pad is told after a try.
@immutable
class PinFeedback {
  const PinFeedback({
    this.wrongCount = 0,
    this.wrong = false,
    this.left,
    this.blockedUntil,
    this.busy = false,
  });

  /// Goes up by one per wrong PIN: a change clears the pad.
  final int wrongCount;

  /// The last PIN was wrong.
  final bool wrong;

  /// The tries left.
  final int? left;
  final DateTime? blockedUntil;

  /// The PIN is being checked.
  final bool busy;

  PinFeedback copyWith({bool? busy}) => PinFeedback(
    wrongCount: wrongCount,
    wrong: wrong,
    left: left,
    blockedUntil: blockedUntil,
    busy: busy ?? this.busy,
  );
}

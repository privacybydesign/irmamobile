import "dart:ui";

import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/data/card_transition/choreography.dart";
import "package:yivi_core/src/screens/data/wallet/wallet_transition.dart"
    show CardMotion;

void main() {
  // Twelve cards, 56 apart, the list scrolled so the first two are off the
  // top; the fifth (index 4) is tapped.
  final cards = [
    for (var i = 0; i < 12; i++) Rect.fromLTWH(16, -60 + i * 56.0, 358, 226),
  ];
  final snapshot = TransitionSnapshot(
    picked: 4,
    cards: cards,
    target: const Rect.fromLTWH(16, 120, 358, 226),
    screenHeight: 844,
  );
  const motion = CardMotion(
    duration: 0.5,
    bounce: 0.4,
    aboveDuration: 0.6,
    fallStagger: 14,
    sinkStagger: 30,
  );
  final c = Choreography(snapshot, motion);

  test("the sinking counts from the first card in sight", () {
    // Card 0's strip ends at -4 (off screen), card 1's at 52.
    expect(snapshot.firstSeen, 1);
    expect(c.openDelay(0), 0);
    expect(c.openDelay(1), 0);
    expect(c.openDelay(2), 30);
    expect(c.openDelay(3), 60);
  });

  test("opening: the uppermost sinks first, the bottom card falls first", () {
    for (var i = 1; i < 3; i++) {
      expect(c.openDelay(i), lessThan(c.openDelay(i + 1)));
    }
    for (var i = 5; i < 11; i++) {
      expect(c.openDelay(i), greaterThan(c.openDelay(i + 1)));
    }
    expect(c.openDelay(4), 0);
  });

  test("closing: the cards nearest the picked one come back first", () {
    expect(c.closeDelay(3), lessThan(c.closeDelay(2)));
    expect(c.closeDelay(5), lessThan(c.closeDelay(6)));
  });

  test("everything is at rest by `settled`", () {
    final end = c.settled.inMilliseconds.toDouble();
    for (var i = 0; i < 12; i++) {
      expect(c.opening(i, end), closeTo(1, 0.002), reason: "card $i open");
      expect(c.closing(i, end, 1), closeTo(0, 0.002), reason: "card $i closed");
    }
  });

  test("closing from halfway through the opening starts where it was", () {
    const at = 150.0;
    for (var i = 0; i < 12; i++) {
      final from = c.opening(i, at);
      expect(c.closing(i, 0, from), from, reason: "no jump for card $i");
    }
  });

  test("closing lands with the same little bounce as opening", () {
    var lowest = 1.0;
    for (var ms = 0.0; ms < 1500; ms += 5) {
      final p = c.closing(4, ms, 1);
      if (p < lowest) lowest = p;
    }
    expect(lowest, lessThan(0));
    expect(lowest, closeTo(1 - c.spring(_peak(c)), 1e-6));
  });

  test("a spring let go with a speed starts at that speed", () {
    const v = 4.0;
    final early = c.spring(1, velocity: v) / 0.001;
    expect(early, closeTo(v, 0.1));
    expect(
      c.spring(c.settled.inMilliseconds.toDouble(), velocity: v),
      closeTo(1, 0.01),
    );
  });

  test("opening again goes on from where it was held", () {
    expect(c.reopening(5, 0, 0.4), 0.4);
    final end = c.settled.inMilliseconds.toDouble();
    expect(c.reopening(5, end, 0.4), closeTo(1, 0.01));
    expect(c.reopening(2, end, 0.4), closeTo(1, 0.01));
  });

  test("the cards below fall far enough to leave the screen", () {
    final next = cards[5].top + c.pose(5, 1).dy;
    expect(next, greaterThanOrEqualTo(844));
    // All by the same distance: they keep their spacing.
    expect(c.pose(9, 1).dy, c.pose(5, 1).dy);
  });

  test("the details show down to the card below as it falls", () {
    expect(c.revealLine(0), cards[5].top);
    expect(c.revealLine(1), greaterThanOrEqualTo(844));
  });

  test("the cards above take their own, slower time", () {
    const ms = 120.0;
    expect(c.opening(2, ms + c.openDelay(2)), lessThan(c.opening(4, ms)));
  });

  test("the cards above bounce too: past their place they rise", () {
    var lowest = 1.0;
    for (var ms = 0.0; ms < 1500; ms += 5) {
      final p = c.closing(3, ms, 1);
      if (p < lowest) lowest = p;
    }
    expect(lowest, lessThan(0));
    final pose = c.pose(3, lowest);
    expect(pose.dy, lessThan(0));
    expect(pose.scale, greaterThan(1));
    expect(pose.opacity, 1);
  });

  test("motion settings from before Wallet give the defaults", () {
    expect(
      CardMotion.decode("0.6,0.5,14,30").encode(),
      CardMotion.defaults.encode(),
    );
    expect(CardMotion.decode(motion.encode()).encode(), motion.encode());
  });

  test("the header goes and comes with the uppermost card", () {
    expect(c.headerOpacity(picked: 0.5, top: 0.8), closeTo(0.2, 1e-9));
    expect(c.headerOpacity(picked: 0.9, top: 0), 1);
  });
}

/// When the spring peaks (its largest value).
double _peak(Choreography c) {
  var best = 0.0, at = 0.0;
  for (var ms = 0.0; ms < 1500; ms += 5) {
    final v = c.spring(ms);
    if (v > best) {
      best = v;
      at = ms;
    }
  }
  return at;
}

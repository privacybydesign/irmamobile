import "dart:ui";

import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/data/card_transition/card_origin.dart";
import "package:yivi_core/src/screens/data/card_transition/choreography.dart";

void main() {
  // Twelve cards, 56 apart, the list scrolled so the first two are off the
  // top; the fifth (index 4) is tapped.
  final cards = [
    for (var i = 0; i < 12; i++) Rect.fromLTWH(16, -60 + i * 56.0, 358, 226),
  ];
  final snapshot = TransitionSnapshot(
    origin: CardOrigin.stack,
    hash: "picked",
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

  test("the stack: the details are there opening, gone in the first half "
      "of closing; nothing else fades", () {
    expect(c.detailsOpacity(0.1, closing: false), 1);
    expect(c.detailsOpacity(1, closing: true), 1);
    expect(c.detailsOpacity(0.75, closing: true), closeTo(0.5, 1e-9));
    expect(c.detailsOpacity(0.5, closing: true), 0);
    expect(c.othersOpacity(0.5), 1);
  });

  group("a tile is a stack of one", () {
    final tile = Choreography(
      const TransitionSnapshot(
        origin: CardOrigin.listRow,
        hash: "row",
        picked: 0,
        cards: [Rect.fromLTWH(24, 500, 88, 55.5)],
        target: Rect.fromLTWH(16, 120, 358, 226),
        screenHeight: 844,
      ),
      motion,
    );

    test("nothing sinks or falls, nothing waits", () {
      expect(tile.snapshot.firstSeen, 0);
      expect(tile.openDelay(0), 0);
      expect(tile.closeDelay(0), 0);
      expect(tile.pose(0, 1).dy, 0);
      final end = tile.settled.inMilliseconds.toDouble();
      expect(tile.opening(0, end), closeTo(1, 0.002));
    });

    test("the header goes in the first 35 % of the way", () {
      expect(tile.headerOpacity(picked: 0, top: 0), 1);
      expect(tile.headerOpacity(picked: 0.35, top: 0.35), 0);
    });

    test("the tab around it goes by 35 % and comes back as it lands", () {
      expect(tile.othersOpacity(0), 1);
      expect(tile.othersOpacity(0.175), closeTo(0.5, 1e-9));
      expect(tile.othersOpacity(0.35), 0);
      expect(tile.othersOpacity(1), 0);
    });

    test("the details come in from 35 % to 100 %, and go the same way", () {
      for (final closing in [false, true]) {
        expect(tile.detailsOpacity(0.35, closing: closing), 0);
        expect(
          tile.detailsOpacity(0.675, closing: closing),
          closeTo(0.5, 1e-9),
        );
        expect(tile.detailsOpacity(1, closing: closing), 1);
      }
    });
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

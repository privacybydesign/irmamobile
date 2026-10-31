import "dart:math";
import "dart:ui";

import "../wallet/wallet_transition.dart" show CardMotion;

/// What is measured once, when a card in the stack is tapped: everything the
/// transition needs, so nothing is measured again while it runs.
class TransitionSnapshot {
  /// The tapped card's place in the stack.
  final int picked;

  /// Every card of the stack where it rests, from the top of the screen.
  final List<Rect> cards;

  /// Where the picked card rests on the details page.
  final Rect target;

  final double screenHeight;

  /// Whether the bar's last button is a + that turns into the details' ✕.
  final bool plusTurnsIntoClose;

  const TransitionSnapshot({
    required this.picked,
    required this.cards,
    required this.target,
    required this.screenHeight,
    this.plusTurnsIntoClose = true,
  });

  int get count => cards.length;

  /// The first card whose strip is on screen: the sinking counts from it
  /// (the ones scrolled off the top are not seen).
  int get firstSeen {
    for (var i = 0; i < picked; i++) {
      final strip = i + 1 < count ? cards[i + 1].top : cards[i].bottom;
      if (strip > 0) return i;
    }
    return picked;
  }
}

/// Where a card of the stack is drawn, apart from where it rests.
class CardPose {
  final double dy;
  final double scale;
  final double opacity;

  /// How dark (0 to 1).
  final double darken;

  const CardPose({
    this.dy = 0,
    this.scale = 1,
    this.opacity = 1,
    this.darken = 0,
  });

  static const rest = CardPose();
}

/// Where everything is during a card's transition, at a time: a pure
/// function of the snapshot, the motion settings and the time. The one
/// place the order of things is decided.
///
/// Every part has a progress, 0 at rest in the list and 1 open: the picked
/// card and its details, each card above (sinking), each card below
/// (falling). Opening, part `i` starts [openDelay] after the tap and rides
/// one spring (with its bounce). Closing, it starts [closeDelay] after the
/// close, from wherever it was then, and does not run past rest.
class Choreography {
  final TransitionSnapshot snapshot;
  final CardMotion motion;

  const Choreography(this.snapshot, this.motion);

  int get _picked => snapshot.picked;

  /// A damped spring from 0 to 1, [ms] after it started, starting at
  /// [velocity] (of the whole way per second: a finger let go). The cards
  /// above the picked one ([above]) take their own, slower time.
  double spring(double ms, {double velocity = 0, bool above = false}) {
    if (ms <= 0) return 0;
    final response = above ? motion.aboveDuration : motion.duration;
    final t = ms / 1000, z = motion.damping, w = 2 * pi / response;
    if (z >= 1) return 1 - exp(-w * t) * (1 + (w - velocity) * t);
    final wd = w * sqrt(1 - z * z);
    return 1 -
        exp(-z * w * t) *
            (cos(wd * t) + ((z * w - velocity) / wd) * sin(wd * t));
  }

  /// Opening: the uppermost visible card sinks first, the bottom card falls
  /// first; the picked card and its details go at once.
  double openDelay(int i) {
    if (i < _picked) {
      return max(0, i - snapshot.firstSeen) * motion.sinkStagger;
    }
    if (i > _picked) return (snapshot.count - 1 - i) * motion.fallStagger;
    return 0;
  }

  /// Closing, mirrored: the cards nearest the picked one come back first.
  double closeDelay(int i) {
    if (i < _picked) return (_picked - 1 - i) * motion.sinkStagger;
    if (i > _picked) return (i - _picked - 1) * motion.fallStagger;
    return 0;
  }

  /// How long until everything is at rest (opening or closing): the
  /// spring within 0.1% of its end, so the page that takes over (or the
  /// stack) does not jump by what is left of it.
  Duration get settled {
    final w = 2 * pi / max(motion.duration, motion.aboveDuration);
    final settle = 6900 / (max(motion.damping, 0.3) * w);
    var delays = 0.0;
    for (var i = 0; i < snapshot.count; i++) {
      delays = max(delays, max(openDelay(i), closeDelay(i)));
    }
    return Duration(milliseconds: (min(settle, 3000) + delays).round());
  }

  /// Progress of part [i], [ms] after the tap.
  double opening(int i, double ms) =>
      spring(ms - openDelay(i), above: i < _picked);

  /// Progress of part [i], [ms] after it was let go (held by a finger) to
  /// open again, coming from [from]: all at once, no more one by one.
  double reopening(int i, double ms, double from) =>
      from + (1 - from) * spring(ms, above: i < _picked);

  /// Progress of part [i], [ms] after the close, coming from [from] (its
  /// progress when the close began), on the same spring: it lands with the
  /// same little bounce (below 0 near the end).
  double closing(int i, double ms, double from) =>
      from * (1 - spring(ms - closeDelay(i), above: i < _picked));

  /// A card of the stack (not the picked one) at progress [p].
  CardPose pose(int i, double p) {
    if (i < _picked) {
      // Past its place (the bounce) it rises a little out of the page.
      final s = p.clamp(-0.35, 1.2);
      return CardPose(
        dy: 60 * s,
        scale: 1 - 0.14 * s,
        opacity: (1 - s).clamp(0.0, 1.0),
        darken: 0.35 * s.clamp(0.0, 1.0),
      );
    }
    if (i > _picked) return CardPose(dy: _drop * p);
    return CardPose.rest;
  }

  /// How far the cards below fall: far enough that the first of them
  /// leaves the screen.
  double get _drop {
    final next = _picked + 1;
    if (next >= snapshot.count) return 0;
    return snapshot.screenHeight - snapshot.cards[next].top + 32;
  }

  /// The line above which the details show, at the progress [next] of the
  /// card just below the picked one: its top as it falls away.
  double revealLine(double next) {
    final i = _picked + 1;
    if (i >= snapshot.count) return snapshot.screenHeight;
    return snapshot.cards[i].top + _drop * next;
  }

  /// The search field and title: they go and come with the uppermost card
  /// in sight ([top], its progress), both ways, so there is never a hole
  /// above the stack; with no card above the picked one, in the first third
  /// of its way ([picked]).
  double headerOpacity({required double picked, required double top}) {
    if (snapshot.firstSeen < _picked) return 1 - top.clamp(0.0, 1.0);
    return 1 - (picked / 0.35).clamp(0.0, 1.0);
  }
}

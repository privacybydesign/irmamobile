import "dart:math";
import "dart:ui";

import "package:flutter/foundation.dart";

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

  const TransitionSnapshot({
    required this.picked,
    required this.cards,
    required this.target,
    required this.screenHeight,
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

  /// The search field and title: they go and come with the uppermost card
  /// in sight ([top], its progress), both ways, so there is never a hole
  /// above the stack; with no card above the picked one, in the first third
  /// of its way ([picked]).
  double headerOpacity({required double picked, required double top}) {
    if (snapshot.firstSeen < _picked) return 1 - top.clamp(0.0, 1.0);
    return 1 - (picked / 0.35).clamp(0.0, 1.0);
  }
}

/// How a card opening from the stack moves (Wallet depth).
@immutable
class CardMotion {
  /// How a card opening from the stack moves now ([CardTransitions]): set
  /// from the preferences at app start, adjustable in the debug settings.
  static final current = ValueNotifier<CardMotion>(CardMotion.defaults);

  /// Of the spring, as iOS sets it: seconds it takes (the card and the
  /// cards below).
  final double duration;

  /// Of the spring: 0 settles without a bounce, more bounces more.
  final double bounce;

  /// Seconds the cards above take: slower, the pile settles behind the
  /// card.
  final double aboveDuration;

  /// Milliseconds between the cards below falling away (the bottom first).
  final double fallStagger;

  /// Milliseconds between the cards above sinking (the uppermost first).
  final double sinkStagger;

  const CardMotion({
    required this.duration,
    required this.bounce,
    required this.aboveDuration,
    required this.fallStagger,
    required this.sinkStagger,
  });

  /// "Wallet", as picked on the prototype (2026-10-31).
  static const defaults = CardMotion(
    duration: 0.35,
    bounce: 0.3,
    aboveDuration: 0.4,
    fallStagger: 0,
    sinkStagger: 0,
  );

  /// The spring's damping ratio (1 settles without a bounce).
  double get damping => 1 - bounce;

  CardMotion copyWith({
    double? duration,
    double? bounce,
    double? aboveDuration,
    double? fallStagger,
    double? sinkStagger,
  }) => CardMotion(
    duration: duration ?? this.duration,
    bounce: bounce ?? this.bounce,
    aboveDuration: aboveDuration ?? this.aboveDuration,
    fallStagger: fallStagger ?? this.fallStagger,
    sinkStagger: sinkStagger ?? this.sinkStagger,
  );

  /// For the preferences: "duration,bounce,above,fall,sink".
  String encode() =>
      "$duration,$bounce,$aboveDuration,$fallStagger,$sinkStagger";

  /// Settings saved in another form (before "Wallet") give the defaults.
  static CardMotion decode(String text) {
    final v = text.split(",").map(double.tryParse).toList();
    if (v.length != 5 || v.contains(null)) return defaults;
    return CardMotion(
      duration: v[0]!,
      bounce: v[1]!,
      aboveDuration: v[2]!,
      fallStagger: v[3]!,
      sinkStagger: v[4]!,
    );
  }
}

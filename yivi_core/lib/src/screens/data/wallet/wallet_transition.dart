import "dart:math";

import "package:flutter/rendering.dart";
import "package:material_ui/material_ui.dart";

import "../../../util/laid_out_box.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/pane_handoff.dart";
import "../../../widgets/slot_registry.dart";
import "../card_transition/card_transition.dart";

/// State shared between the data tab and the card detail route while a card
/// opens or closes, for the Wallet-style transition: the tapped card glides
/// to the top while everything above it is pushed up and away and everything
/// below it is pushed down.
///
/// The home route's `secondaryAnimation` runs for every route pushed on top of
/// it, so [PushAway] only moves while [openKey] is set: from the moment a
/// card is tapped until its detail route has closed again.
class WalletTransition {
  WalletTransition._();

  /// The same time both ways.
  static const duration = Duration(milliseconds: 500);
  static const reverseDuration = duration;

  /// One curve for everything that moves (the card, the other cards, the
  /// bar): gentle at both ends, so it reads as one movement.
  static const curve = Curves.fastOutSlowIn;

  /// What moves (the card, the other cards) settles with a little bounce:
  /// it runs a few percent past its place and back ([moved]).
  static const settleCurve = Cubic(0.3, 1.25, 0.5, 1);

  /// At most this far past its place, however far it flew.
  static const maxOvershoot = 10.0;

  /// Whether the open card is closing (its detail route runs in reverse).
  static bool closing = false;

  /// Progress of the open transition (0 closed, 1 open) at [value] of the
  /// route animation: [curve] from where it starts, both ways, so closing
  /// also leaves quickly and settles gently (not the opening played back,
  /// which starts slowly).
  static double eased(double value) {
    final v = value.clamp(0.0, 1.0);
    return closing ? 1 - curve.transform(1 - v) : curve.transform(v);
  }

  /// Key of what is open (or opening/closing): a card's hash, or an
  /// activity entry's key.
  static final openKey = ValueNotifier<String?>(null);

  /// Global y-coordinate of the tapped card's top edge; items above it move
  /// up, items below move down.
  static double anchorY = 0;

  static String heroTag(String hash) => "card-art-$hash";

  /// Whether the page below has a + in its bar that turns into the
  /// detail's close button ([WalletBar.plusTurnsIntoClose]); otherwise the
  /// close button turns in by itself.
  static bool closeFromPlus = false;

  /// Call when a card is tapped, just before pushing its detail route.
  static void begin(BuildContext cardContext, String hash) {
    final box = cardContext.findRenderObject() as RenderBox?;
    anchorY = box?.localToGlobal(Offset.zero).dy ?? 0;
    closeFromPlus = WalletBar.maybeOf(cardContext)?.plusTurnsIntoClose ?? false;
    stack = StackOpen.of(cardContext, box);
    reverseFrom = 1;
    pullAtClose = 0;
    openKey.value = hash;
  }

  // ------------------------------------------- Wallet depth (the card stack)

  /// How a card opening from the stack moves; adjustable in the debug
  /// settings.
  static final motion = ValueNotifier<CardMotion>(CardMotion.defaults);

  /// The card opening from (or closing into) the stack, or null when what
  /// opens is not in the stack (Activity, a row, a grid card).
  static StackOpen? stack;

  /// How long the detail route runs: until the stack's spring has settled.
  static Duration get routeDuration {
    final open = stack;
    if (open == null) return duration;
    final m = motion.value;
    final w = 2 * pi / m.response;
    final settle = min(2600.0, 4600 / (max(m.damping, 0.3) * w) + 120);
    final delays = min(900.0, open.count * max(m.fallStagger, m.sinkStagger));
    return Duration(milliseconds: (settle + delays).round());
  }

  /// A damped spring from 0 to 1, [ms] after it started ([motion]).
  static double spring(double ms) {
    if (ms <= 0) return 0;
    final m = motion.value;
    final t = ms / 1000, z = m.damping, w = 2 * pi / m.response;
    if (z >= 1) return 1 - exp(-w * t) * (1 + w * t);
    final wd = w * sqrt(1 - z * z);
    return 1 - exp(-z * w * t) * (cos(wd * t) + (z * w / wd) * sin(wd * t));
  }

  /// Where the route animation was when it started closing: a close that
  /// interrupts the opening goes on from where everything is then.
  static double reverseFrom = 1;

  /// How far the details page was pulled down when it started closing:
  /// the card flies back from there.
  static double pullAtClose = 0;

  /// How open (0 closed, 1 open) something is at [value] of the route
  /// animation. The one place every part of the transition asks (the card,
  /// its details, the cards above and below, the bar), so they never drift
  /// apart. Opening, it starts [openDelay] ms after the tap, on the spring
  /// (with its bounce); closing, [closeDelay] ms after the close, from
  /// wherever it was then, and without running past where it lands.
  static double stackOpen(
    double value, {
    double openDelay = 0,
    double closeDelay = 0,
  }) {
    final total = routeDuration.inMilliseconds.toDouble();
    if (!closing) return spring(value * total - openDelay);
    final v0 = reverseFrom;
    final from = v0 >= 1 ? 1.0 : spring(v0 * total - openDelay).clamp(0.0, 1.2);
    final f = v0 <= 0 ? 1.0 : ((v0 - value) / v0).clamp(0.0, 1.0);
    final back = spring(f * total - closeDelay).clamp(0.0, 1.0);
    return from * (1 - back);
  }

  /// How far a close has got (0 just started, 1 done) at [value] of the
  /// route animation, also when it interrupted the opening.
  static double closeFraction(double value) {
    final v0 = reverseFrom;
    return v0 <= 0 ? 1 : ((v0 - value) / v0).clamp(0.0, 1.0);
  }

  /// Where the opening card's top edge is now, from the top of the screen.
  static double stackCardTop(double value) {
    final open = stack!;
    final top = open.targetTop + pullAtClose;
    return anchorY + (top - anchorY) * stackOpen(value);
  }

  /// How far the card just below the opening one is on its way down.
  static double _nextDown(double value) {
    final open = stack!;
    final m = motion.value;
    final next = open.index + 1;
    return stackOpen(value, openDelay: (open.count - 1 - next) * m.fallStagger);
  }

  /// The line (from the top of the screen) above which the details show:
  /// the top of the card just below the opening one, as it slides away.
  static double stackRevealLine(double value, double screenHeight) {
    final open = stack!;
    final next = open.nextTop;
    if (next == null) return screenHeight;
    return next + (screenHeight - next + 32) * _nextDown(value);
  }

  /// How far what moves has gone (0 closed, 1 open) at [value] of the
  /// route animation: as [eased], with the bounce of [settleCurve] (below 0
  /// or above 1 near the end). See [overshoot] for how far that may go.
  static double moved(double value) {
    final v = value.clamp(0.0, 1.0);
    return closing
        ? 1 - settleCurve.transform(1 - v)
        : settleCurve.transform(v);
  }

  /// [distance] × [t], but past either end by at most [maxOvershoot].
  static double overshoot(double t, double distance) {
    final past = switch (t) {
      > 1 => (t - 1) * distance,
      < 0 => t * distance,
      _ => 0.0,
    };
    final within = t.clamp(0.0, 1.0) * distance;
    return within + past.clamp(-maxOvershoot, maxOvershoot);
  }

  /// How far the bars have handed over (0 to 1) at [value] of the route
  /// animation: as everything else ([eased]).
  static double barProgress(double value) =>
      stack == null ? eased(value) : stackOpen(value).clamp(0.0, 1.0);

  /// The close button of a detail page at [value] of its route animation:
  /// its opacity and its turn in degrees. It takes over from a + that turned
  /// into it ([closeFromPlus]) at the end; otherwise it turns in from -45°
  /// as the bar's buttons go.
  static (double opacity, double turn) closeButton(double value) {
    final p = barProgress(value);
    double iv(double a, double b) => ((p - a) / (b - a)).clamp(0.0, 1.0);
    if (closeFromPlus) return (iv(0.85, 1), 0);
    return (iv(0.35, 0.8), -45 * (1 - iv(0.3, 0.9)));
  }

  /// Hero rect tween that follows [curve] in a straight line, instead of the
  /// default Material arc.
  static RectTween rectTween(Rect? begin, Rect? end) =>
      _CurvedRectTween(begin: begin, end: end);

  /// How far the [index]th of several cards that fly together is from its
  /// closed place (0) to its open place (1), at [value] of the route
  /// animation. Each starts a little later (about 30 ms each), so they fan
  /// out one by one; closing, they come back together, [curve] from where
  /// they start.
  static double staggered(double value, int index) {
    if (closing) return eased(value);
    final start = (index * 0.065).clamp(0.0, 0.3);
    return curve.transform(Interval(start, 1).transform(value));
  }
}

class _CurvedRectTween extends RectTween {
  _CurvedRectTween({super.begin, super.end});

  // Both ways from where it starts, with the bounce of
  // [WalletTransition.settleCurve], at most [WalletTransition.maxOvershoot]
  // past where it lands (a popping hero flies from the detail, t = 0, to
  // the list, t = 1).
  @override
  Rect? lerp(double t) {
    final b = begin, e = end;
    if (b == null || e == null) return super.lerp(t);
    // From the stack: where everything else says the card is
    // (WalletTransition.stackOpen). The tween from the list (opening, or an
    // opening turned into a close) runs with the route; the one from the
    // details (closing) against it.
    if (WalletTransition.stack != null) {
      final anchor = WalletTransition.anchorY;
      final fromList = (b.top - anchor).abs() <= (e.top - anchor).abs();
      return fromList
          ? Rect.lerp(b, e, WalletTransition.stackOpen(t))
          : Rect.lerp(e, b, WalletTransition.stackOpen(1 - t));
    }
    final s = WalletTransition.settleCurve.transform(t);
    return Rect.fromLTWH(
      b.left + WalletTransition.overshoot(s, e.left - b.left),
      b.top + WalletTransition.overshoot(s, e.top - b.top),
      b.width + WalletTransition.overshoot(s, e.width - b.width),
      b.height + WalletTransition.overshoot(s, e.height - b.height),
    );
  }
}

enum PushAwayDirection {
  /// Decide from the position: above the tapped card moves up, below moves down.
  auto,
  up,
  down,
}

/// Moves its child out of the way while a card detail route opens over this
/// route, and back while it closes. Wrap every list item and the floating
/// controls in one. The card with [hash] equal to the opening card does not
/// move: its picture flies to the detail view as a [Hero].
class PushAway extends StatelessWidget {
  final Widget child;
  final PushAwayDirection direction;
  final String? hash;

  /// For rows whose card picture is only a thumbnail: the opening card's own
  /// row fades out instead of staying put.
  final bool fadeWhenOpening;

  /// Its place in the card stack, for Wallet depth ([StackOpen]): above the
  /// opening card it sinks into the screen, below it it falls away.
  final int? stackIndex;

  const PushAway({
    super.key,
    required this.child,
    this.direction = PushAwayDirection.auto,
    this.hash,
    this.fadeWhenOpening = false,
    this.stackIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (stackIndex case final i?) StackOpen._slots[i] = context;
    final secondary = ModalRoute.of(context)?.secondaryAnimation;
    if (secondary == null || MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    return ValueListenableBuilder<String?>(
      valueListenable: WalletTransition.openKey,
      builder: (context, openKey, child) {
        if (openKey == null) return child!;
        if (openKey == hash) {
          if (!fadeWhenOpening) return child!;
          return FadeTransition(
            opacity: ReverseAnimation(
              CurvedAnimation(parent: secondary, curve: const Interval(0, 0.5)),
            ),
            child: child,
          );
        }
        final bar = WalletBar.maybeOf(context);
        return AnimatedBuilder(
          animation: secondary,
          builder: (context, child) {
            final stack = WalletTransition.stack;
            if (stack != null) {
              return _inStack(context, stack, secondary.value, child!);
            }
            final t = WalletTransition.eased(secondary.value);
            if (t == 0) return child!;
            final moved = WalletTransition.moved(secondary.value);
            if (bar != null) return _underBar(context, t, moved, child!);
            return Transform.translate(
              offset: Offset(
                0,
                WalletTransition.overshoot(moved, _distance(context)),
              ),
              child: child,
            );
          },
          child: child,
        );
      },
      child: child,
    );
  }

  /// Under a home tab's bar ([WalletBar]), as Wallet: only the tapped item
  /// goes up. The header ([PushAwayDirection.up]) fades where it is; every
  /// other item, above the tapped one or below it, goes down off the screen,
  /// all by the same distance, so the list drops as one (what was above
  /// passes behind the flying item).
  Widget _underBar(BuildContext context, double t, double moved, Widget child) {
    if (direction == PushAwayDirection.up ||
        !(WalletBar.maybeOf(context)?.othersDrop ?? true)) {
      // Gone in the first third of opening; closing, back while the
      // details fade out (the first fifth), so the screen is never empty.
      final opacity = WalletTransition.closing
          ? 1 - ((t - 0.8) / 0.17).clamp(0.0, 1.0)
          : 1 - (t / 0.35).clamp(0.0, 1.0);
      return Opacity(opacity: opacity, child: child);
    }
    // Far enough that even an item at the very top ends below the screen.
    // One scrolled off the top stays hidden: dropping by the same distance
    // would bring it into view.
    final box = context.findRenderObject() as RenderBox?;
    final height = box != null && box.hasSize ? box.size.height : 0.0;
    if (box != null &&
        box.hasSize &&
        box.localToGlobal(Offset(0, height)).dy <= 0) {
      // Kept (with its state), only not drawn.
      return Opacity(opacity: 0, child: child);
    }
    final drop = MediaQuery.sizeOf(context).height + 32 + height;
    return Transform.translate(
      offset: Offset(0, WalletTransition.overshoot(moved, drop)),
      child: child,
    );
  }

  /// While a card opens from the stack (Wallet depth): the cards above it
  /// sink into the screen one after another, the uppermost first, never
  /// showing below the opening card; the cards below fall away, the bottom
  /// one first. The header fades where it is, and comes back with the
  /// uppermost card. The rest (the tab bar) goes down with the spring.
  Widget _inStack(
    BuildContext context,
    StackOpen open,
    double value,
    Widget child,
  ) {
    final m = WalletTransition.motion.value;
    final closing = WalletTransition.closing;
    final i = stackIndex;
    final box = context.findRenderObject() as RenderBox?;
    final top = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero).dy
        : 0.0;
    if (i != null && i < open.index) {
      final s = WalletTransition.stackOpen(
        value,
        openDelay: (i - open.firstSeen) * m.sinkStagger,
        closeDelay: (open.index - 1 - i) * m.sinkStagger,
      ).clamp(0.0, 1.2);
      if (s == 0) return child;
      final k = 1 - 0.14 * s;
      final cut =
          WalletTransition.stackCardTop(value) + open.cardHeight - top - 60 * s;
      return Opacity(
        opacity: (1 - s).clamp(0.0, 1.0),
        child: Transform(
          alignment: Alignment.topCenter,
          transform: Matrix4.translationValues(0, 60 * s, 0)
            ..scaleByDouble(k, k, 1, 1),
          child: ClipRect(
            clipper: ClipAboveY(cut / k),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.35 * s.clamp(0.0, 1.0)),
                BlendMode.srcATop,
              ),
              child: child,
            ),
          ),
        ),
      );
    }
    final screen = MediaQuery.sizeOf(context).height;
    if (i != null && i > open.index) {
      final p = WalletTransition.stackOpen(
        value,
        openDelay: (open.count - 1 - i) * m.fallStagger,
        closeDelay: (i - open.index - 1) * m.fallStagger,
      );
      final from = open.nextTop ?? top;
      return Transform.translate(
        offset: Offset(0, (screen - from + 32) * p),
        child: child,
      );
    }
    if (direction == PushAwayDirection.up) {
      final back = closing && open.index > open.firstSeen
          ? 1 -
                WalletTransition.stackOpen(
                  value,
                  closeDelay: (open.index - 1 - open.firstSeen) * m.sinkStagger,
                ).clamp(0.0, 1.0)
          : 1 - (WalletTransition.barProgress(value) / 0.35).clamp(0.0, 1.0);
      return Opacity(opacity: back, child: child);
    }
    final p = WalletTransition.stackOpen(value);
    return Transform.translate(
      offset: Offset(0, (screen - top + 32) * p),
      child: child,
    );
  }

  /// How far it goes: off the screen, up or down.
  double _distance(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return 0;
    final top = box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;
    final screen = MediaQuery.sizeOf(context).height;
    final up = switch (direction) {
      PushAwayDirection.up => true,
      PushAwayDirection.down => false,
      PushAwayDirection.auto => top < WalletTransition.anchorY - 1,
    };
    return up ? -(bottom + 32) : (screen - top + 32);
  }
}

/// The bar of a home tab (`HomeTabTop`), for what opens from under it: it
/// stays while a card or an entry opens; the header under it fades and the
/// rest of the list drops away ([PushAway]).
class WalletBar extends InheritedWidget {
  /// Whether the bar's last button is a + that turns into the detail's
  /// close button ([WalletTransition.closeFromPlus]).
  final bool plusTurnsIntoClose;

  /// Whether the other items drop away together (cards, which lie over each
  /// other, as in Wallet); otherwise they fade where they are (rows: one
  /// dropping through another would show its text over it).
  final bool othersDrop;

  const WalletBar({
    super.key,
    required this.plusTurnsIntoClose,
    this.othersDrop = true,
    required super.child,
  });

  static WalletBar? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WalletBar>();

  @override
  bool updateShouldNotify(WalletBar oldWidget) =>
      oldWidget.plusTurnsIntoClose != plusTurnsIntoClose ||
      oldWidget.othersDrop != othersDrop;
}

/// The page of the card detail route. It draws no transition of its own: the
/// card flies as a [Hero] and the detail fades in itself.
///
/// It also hands the route below (home) a [ModalRoute.delegatedTransition]
/// that leaves that page where it is. Without one a Material route below
/// does not run its `secondaryAnimation` for this route, and [PushAway]
/// would never move the search bar, the other cards and the tab bar.
class WalletDetailPage<T> extends Page<T> {
  final Widget child;

  const WalletDetailPage({super.key, super.name, required this.child});

  @override
  Route<T> createRoute(BuildContext context) => _WalletDetailRoute<T>(this);
}

class _WalletDetailRoute<T> extends PageRoute<T> with InstantRouteMixin<T> {
  _WalletDetailRoute(WalletDetailPage<T> page) : super(settings: page);

  WalletDetailPage<T> get _page => settings as WalletDetailPage<T>;

  // Not opaque, so the data tab stays painted while its items move away.
  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  /// Opened by a card transition ([CardTransitions]): it has drawn the
  /// way here (and draws the way back), so the page comes and goes at once,
  /// without heroes.
  bool get _byCardTransition =>
      navigator != null &&
      (CardTransitionScope.maybeOf(navigator!.context)?.busy ?? false);

  @override
  Duration get transitionDuration =>
      _byCardTransition ? Duration.zero : WalletTransition.routeDuration;

  @override
  Duration get reverseTransitionDuration =>
      _byCardTransition ? Duration.zero : WalletTransition.routeDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => _stayInPlace;

  static Widget? _stayInPlace(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) => child;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => HeroMode(enabled: !_byCardTransition, child: _page.child);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

/// A card's place in the Stack view of the data tab. Cards lower in the
/// stack are drawn over the ones above them; a card flying into or out of
/// its place ([CoveredByStack]) uses this to slide under the card below it.
class WalletStackSlot extends StatefulWidget {
  final String hash;
  final int index;
  final Widget child;

  const WalletStackSlot({
    super.key,
    required this.hash,
    required this.index,
    required this.child,
  });

  static final _byIndex = SlotRegistry<int>();
  static final _indexOf = <String, int>{};

  /// The card drawn over [hash]'s place: the next card down the stack. For a
  /// card that is not in the stack yet ([incoming]), the first card, which it
  /// will slide under. Null outside the Stack view.
  static RenderBox? coverOf(String hash, {bool incoming = false}) {
    final index = _indexOf[hash];
    final cover = index != null
        ? _byIndex[index + 1]
        : (incoming ? _byIndex[0] : null);
    return cover.laidOutBox;
  }

  @override
  State<WalletStackSlot> createState() => _WalletStackSlotState();
}

class _WalletStackSlotState extends State<WalletStackSlot> {
  void _register() {
    WalletStackSlot._byIndex.put(widget.index, context);
    WalletStackSlot._indexOf[widget.hash] = widget.index;
  }

  void _unregister(WalletStackSlot old) {
    WalletStackSlot._byIndex.drop(old.index, context);
    if (WalletStackSlot._indexOf[old.hash] == old.index) {
      WalletStackSlot._indexOf.remove(old.hash);
    }
  }

  @override
  void didUpdateWidget(WalletStackSlot old) {
    super.didUpdateWidget(old);
    _unregister(old);
  }

  @override
  void dispose() {
    _unregister(widget);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _register();
    return widget.child;
  }
}

/// Hides the part of a flying card that the cards below its place in the
/// stack cover, every frame ([repaint]), so it slides under the card below it
/// and over the one above it instead of flying over all of them and jumping
/// under at the end.
class CoveredByStack extends SingleChildRenderObjectWidget {
  final String hash;

  /// The card is not in the stack yet: it slides under the first card.
  final bool incoming;
  final Listenable repaint;

  const CoveredByStack({
    super.key,
    required this.hash,
    required this.repaint,
    this.incoming = false,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderCoveredByStack(hash, incoming, repaint);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderCoveredByStack renderObject,
  ) {
    renderObject
      ..hash = hash
      ..incoming = incoming
      ..repaint = repaint;
  }
}

class RenderCoveredByStack extends RenderProxyBox {
  RenderCoveredByStack(this.hash, this.incoming, this._repaint);

  String hash;
  bool incoming;
  Listenable _repaint;

  set repaint(Listenable value) {
    if (value == _repaint) return;
    if (attached) _repaint.removeListener(markNeedsPaint);
    _repaint = value;
    if (attached) _repaint.addListener(markNeedsPaint);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _repaint.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _repaint.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final cover = WalletStackSlot.coverOf(hash, incoming: incoming);
    if (cover == null || child == null) {
      super.paint(context, offset);
      return;
    }
    // The covering card in this box's coordinates, reaching far down: the
    // cards after it cover the rest of the stack.
    final coverTop = globalToLocal(cover.localToGlobal(Offset.zero));
    final coverRect = Rect.fromLTWH(
      coverTop.dx,
      coverTop.dy,
      cover.size.width,
      cover.size.height + 10000,
    );
    final covered = CredentialCardArt.shapeFor(
      cover.size.width,
    ).getOuterPath(coverRect);
    // Room around the card for its shadow.
    final visible = Path.combine(
      PathOperation.difference,
      Path()..addRect((Offset.zero & size).inflate(48)),
      covered,
    );
    context.pushClipPath(
      needsCompositing,
      offset,
      (Offset.zero & size).inflate(48),
      visible,
      super.paint,
    );
  }
}

/// Clips to what is above [y] (in the child's coordinates).
class ClipAboveY extends CustomClipper<Rect> {
  final double y;

  const ClipAboveY(this.y);

  @override
  Rect getClip(Size size) => Rect.fromLTRB(-1e5, -1e5, 1e5, y);

  @override
  bool shouldReclip(ClipAboveY oldClipper) => oldClipper.y != y;
}

/// How a card opening from the stack moves (Wallet depth).
@immutable
class CardMotion {
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

  /// Seconds for one swing of the spring.
  double get response => duration;

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

/// A card opening from the stack: its place in it, and where the others
/// are, measured when it is tapped.
class StackOpen {
  /// Where each card of the stack is built ([PushAway.stackIndex]).
  static final _slots = <int, BuildContext>{};

  final int index;
  final int count;

  /// The first card whose strip is on screen: the sinking counts from it.
  final int firstSeen;
  final double cardHeight;

  /// Where the card's top lands on the details page.
  final double targetTop;

  /// The top of the card just below it, or null for the last card.
  final double? nextTop;

  const StackOpen({
    required this.index,
    required this.count,
    required this.firstSeen,
    required this.cardHeight,
    required this.targetTop,
    required this.nextTop,
  });

  /// For the card at [cardContext] ([box] its card), when it is in the
  /// stack.
  static StackOpen? of(BuildContext cardContext, RenderBox? box) {
    final index = cardContext
        .findAncestorWidgetOfExactType<PushAway>()
        ?.stackIndex;
    if (index == null || box == null || !box.hasSize) return null;
    double? topOf(int i) {
      final c = _slots[i];
      if (c == null || !c.mounted) return null;
      final b = c.findRenderObject();
      if (b is! RenderBox || !b.hasSize || !b.attached) return null;
      return b.localToGlobal(Offset.zero).dy;
    }

    // Only the cards there now (a card deleted or the list rebuilt leaves
    // old entries behind).
    _slots.removeWhere((_, c) => !c.mounted);
    final count = _slots.keys.fold(0, (n, i) => max(n, i + 1));
    final strip = (topOf(index + 1) ?? 0) - (topOf(index) ?? 0);
    var firstSeen = 0;
    for (var i = 0; i < index; i++) {
      final t = topOf(i);
      if (t != null && t + max(strip, 1) > 0) {
        firstSeen = i;
        break;
      }
      firstSeen = i + 1;
    }
    return StackOpen(
      index: index,
      count: count,
      firstSeen: min(firstSeen, index),
      cardHeight: box.size.height,
      targetTop: MediaQuery.paddingOf(cardContext).top + IrmaAppBar.contentTop,
      nextTop: index + 1 < count ? topOf(index + 1) : null,
    );
  }
}

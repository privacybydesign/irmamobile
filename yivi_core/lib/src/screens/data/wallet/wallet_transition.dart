import "package:flutter/rendering.dart";
import "package:material_ui/material_ui.dart";

import "../../../util/laid_out_box.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/pane_handoff.dart";
import "../../../widgets/slot_registry.dart";
import "../card_transition/card_transition.dart";
import "../card_transition/repaints_with.dart";

/// State shared between a home tab and the detail route of what opens from
/// it (a card from the list or grid, an activity entry): the tapped item
/// flies to the top while the rest of the list moves away ([PushAway]).
/// Cards in the stack move in place instead ([CardTransitions]).
///
/// The home route's `secondaryAnimation` runs for every route pushed on top of
/// it, so [PushAway] only moves while [openKey] is set: from the moment a
/// card is tapped until its detail route has closed again.
class WalletTransition {
  WalletTransition._();

  /// The same time both ways.
  static const duration = Duration(milliseconds: 500);

  /// One curve for everything that moves (the card, the other cards, the
  /// bar): gentle at both ends, so it reads as one movement.
  static const curve = Curves.fastOutSlowIn;

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
    openKey.value = hash;
  }

  /// How far the bars have handed over (0 to 1) at [value] of the route
  /// animation: as everything else ([eased]).
  static double barProgress(double value) => eased(value);

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
}

class _CurvedRectTween extends RectTween {
  _CurvedRectTween({super.begin, super.end});

  // Both ways from where it starts, [WalletTransition.curve] without a
  // bounce (a popping hero flies from the detail, t = 0, to the list,
  // t = 1).
  @override
  Rect? lerp(double t) {
    final b = begin, e = end;
    if (b == null || e == null) return super.lerp(t);
    return Rect.lerp(b, e, WalletTransition.curve.transform(t));
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

  const PushAway({
    super.key,
    required this.child,
    this.direction = PushAwayDirection.auto,
    this.hash,
    this.fadeWhenOpening = false,
  });

  @override
  Widget build(BuildContext context) {
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
            final t = WalletTransition.eased(secondary.value);
            if (t == 0) return child!;
            if (bar != null) return _underBar(context, t, child!);
            return Transform.translate(
              offset: Offset(0, t * _distance(context)),
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
  Widget _underBar(BuildContext context, double t, Widget child) {
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
    return Transform.translate(offset: Offset(0, t * drop), child: child);
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

  @override
  Duration get transitionDuration => WalletTransition.duration;

  @override
  Duration get reverseTransitionDuration => WalletTransition.duration;

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
  ) => _page.child;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

/// A card's place in the Stack view of the data tab. Cards lower in the
/// stack are drawn over the ones above them; a received card flying into
/// the stack ([CoveredByStack]) uses this to slide under the card below.
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

  /// The card at [index] of the stack, once laid out: where it rests (the
  /// card transition measures it here).
  static RenderBox? boxAt(int index) => _byIndex[index].laidOutBox;

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
/// stack cover, every frame ([repaint]), so it slides under them instead of
/// flying over all of them and jumping under at the end.
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

class RenderCoveredByStack extends RenderProxyBox with RepaintsWith {
  RenderCoveredByStack(this.hash, this.incoming, Listenable repaint) {
    repaintSource = repaint;
  }

  String hash;
  bool incoming;

  set repaint(Listenable value) => repaintSource = value;

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

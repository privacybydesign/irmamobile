import "package:flutter/rendering.dart";
import "package:material_ui/material_ui.dart";

import "../../../widgets/credential_card/card_art/credential_card_art.dart";

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

  static const duration = Duration(milliseconds: 460);

  /// Closing takes a little longer, for the settle at the end.
  static const reverseDuration = Duration(milliseconds: 560);
  static const curve = Cubic(0.2, 0.8, 0.2, 1);

  /// The curve of closing: a spring that runs a few percent past the end
  /// and settles back, so the card lands in the stack with a slight bounce
  /// and the other cards bounce back into place.
  static const closeCurve = Cubic(0.34, 1.3, 0.64, 1);

  /// Whether the open card is closing (its detail route runs in reverse).
  static bool closing = false;

  /// Progress of the open transition (0 closed, 1 open) at [value] of the
  /// route animation, eased: [curve] while opening, [closeCurve] played from
  /// the open end while closing (so the overshoot happens on landing).
  static double eased(double value) =>
      closing ? 1 - closeCurve.transform(1 - value) : curve.transform(value);

  /// Key of what is open (or opening/closing): a card's hash, or an
  /// activity entry's key.
  static final openKey = ValueNotifier<String?>(null);

  /// Global y-coordinate of the tapped card's top edge; items above it move
  /// up, items below move down.
  static double anchorY = 0;

  static String heroTag(String hash) => "card-art-$hash";

  /// Call when a card is tapped, just before pushing its detail route.
  static void begin(BuildContext cardContext, String hash) {
    final box = cardContext.findRenderObject() as RenderBox?;
    anchorY = box?.localToGlobal(Offset.zero).dy ?? 0;
    openKey.value = hash;
  }

  /// Hero rect tween that follows [curve] in a straight line, instead of the
  /// default Material arc.
  static RectTween rectTween(Rect? begin, Rect? end) =>
      _CurvedRectTween(begin: begin, end: end);

  /// How far the [index]th of several cards that fly together is from its
  /// closed place (0) to its open place (1), at [value] of the route
  /// animation. Each starts a little later (about 30 ms each), so they fan
  /// out one by one; [curve] while opening, [closeCurve] while closing (so
  /// the overshoot happens on landing).
  static double staggered(double value, int index) {
    final start = (index * 0.065).clamp(0.0, 0.3);
    if (closing) {
      final delayed = Interval(start, 1).transform(1 - value);
      return 1 - closeCurve.transform(delayed);
    }
    return curve.transform(Interval(start, 1).transform(value));
  }
}

class _CurvedRectTween extends RectTween {
  _CurvedRectTween({super.begin, super.end});

  // A popping hero flies from the detail (t = 0) to the card in the list
  // (t = 1), so closing uses [WalletTransition.closeCurve] forwards.
  @override
  Rect? lerp(double t) => super.lerp(
    WalletTransition.closing
        ? WalletTransition.closeCurve.transform(t)
        : WalletTransition.curve.transform(t),
  );
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
        return AnimatedBuilder(
          animation: secondary,
          builder: (context, child) {
            final t = WalletTransition.eased(secondary.value);
            if (t == 0) return child!;
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

class _WalletDetailRoute<T> extends PageRoute<T> {
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
  Duration get reverseTransitionDuration => WalletTransition.reverseDuration;

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

  static final _byIndex = <int, BuildContext>{};
  static final _indexOf = <String, int>{};

  /// The card drawn over [hash]'s place: the next card down the stack. For a
  /// card that is not in the stack yet ([incoming]), the first card, which it
  /// will slide under. Null outside the Stack view.
  static RenderBox? coverOf(String hash, {bool incoming = false}) {
    final index = _indexOf[hash];
    final cover = index != null
        ? _byIndex[index + 1]
        : (incoming ? _byIndex[0] : null);
    if (cover == null || !cover.mounted) return null;
    final box = cover.findRenderObject();
    return box is RenderBox && box.attached && box.hasSize ? box : null;
  }

  @override
  State<WalletStackSlot> createState() => _WalletStackSlotState();
}

class _WalletStackSlotState extends State<WalletStackSlot> {
  void _register() {
    WalletStackSlot._byIndex[widget.index] = context;
    WalletStackSlot._indexOf[widget.hash] = widget.index;
  }

  void _unregister(WalletStackSlot old) {
    if (WalletStackSlot._byIndex[old.index] == context) {
      WalletStackSlot._byIndex.remove(old.index);
    }
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

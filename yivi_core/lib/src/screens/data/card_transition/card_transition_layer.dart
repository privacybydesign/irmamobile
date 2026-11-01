import "package:flutter/gestures.dart" show Drag;
import "package:flutter/rendering.dart";
import "package:flutter/scheduler.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "card_transition.dart";
import "choreography.dart";

/// The open card's details, over the home screen, from the tap until the
/// card is back in the stack: the real ones (the card at the top and all
/// under it), never a picture or a copy, so nothing changes when the motion
/// ends or starts.
///
/// While the card moves they are moved and scaled so that their card is
/// where the transition puts it, and only the card and the band under it
/// (down to the card below as it falls away) are shown. Open, they are
/// shown as they are, and take touches. Nothing is built again per frame:
/// only where they are painted changes ([_RenderOpenCard]).
class OpenCardLayer extends StatelessWidget {
  /// The widest the open card and its details are, here and on the details
  /// page, so the card lands where the page draws it.
  static const double detailsMaxWidth = 460;

  const OpenCardLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = CardTransitionScope.maybeOf(context);
    if (scope == null) return const SizedBox.shrink();
    return ValueListenableBuilder<CardTransition?>(
      valueListenable: scope.current,
      builder: (context, t, _) => t == null
          ? const SizedBox.shrink()
          : _OpenCard(key: ObjectKey(t), transition: t),
    );
  }
}

class _OpenCard extends StatefulWidget {
  final CardTransition transition;

  const _OpenCard({super.key, required this.transition});

  @override
  State<_OpenCard> createState() => _OpenCardState();
}

class _OpenCardState extends State<_OpenCard> {
  /// A drag up that took over from the opening: it scrolls the details.
  Drag? _scroll;

  @override
  void initState() {
    super.initState();
    // The motion starts once the details are built and drawn: their first
    // frame shows the card where it was tapped.
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => widget.transition.ready(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transition;
    final card = _OpenCardRender(
      transition: t,
      background: YiviPalette.of(context).background,
      child: RepaintBoundary(child: t.details(context, t)),
    );
    // While it moves, a finger anywhere takes hold of it (nothing under it
    // scrolls or is tapped): the card stops and follows the finger down,
    // and let go it closes or opens again. Pushed up as it opens, it is
    // open at once and the finger scrolls the details. Open, the details
    // take touches themselves (their pull down closes).
    return ValueListenableBuilder<TransitionPhase>(
      valueListenable: t.phaseListenable,
      child: card,
      builder: (context, phase, card) => Stack(
        fit: StackFit.expand,
        children: [
          card!,
          // Kept while a drag that took over scrolls the details.
          if (phase != TransitionPhase.open || _scroll != null)
            _TouchGate(
              transition: t,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragDown: (_) => t.grab(),
                onVerticalDragUpdate: _update,
                onVerticalDragEnd: _end,
                onVerticalDragCancel: _cancel,
              ),
            ),
        ],
      ),
    );
  }

  void _update(DragUpdateDetails d) {
    final t = widget.transition;
    if (_scroll case final scroll?) return scroll.update(d);
    if (d.delta.dy < 0) {
      final details = t.cardKey.currentContext;
      final position = details == null
          ? null
          : Scrollable.maybeOf(details)?.position;
      if (position != null && t.handOver()) {
        setState(() {
          _scroll = position.drag(
            DragStartDetails(
              globalPosition: d.globalPosition,
              localPosition: d.localPosition,
              sourceTimeStamp: d.sourceTimeStamp,
            ),
            () => _scroll = null,
          );
        });
        return _scroll!.update(d);
      }
    }
    t.drag(d.delta.dy);
  }

  void _end(DragEndDetails d) {
    if (_scroll case final scroll?) {
      scroll.end(d);
      return setState(() => _scroll = null);
    }
    widget.transition.letGo(d.velocity.pixelsPerSecond.dy);
  }

  void _cancel() {
    if (_scroll case final scroll?) {
      scroll.cancel();
      return setState(() => _scroll = null);
    }
    widget.transition.letGo(0);
  }
}

/// Lets a touch through to what is under it when the card is (almost)
/// where it goes ([CardTransition.passTouch]): the list then scrolls, or the
/// details, instead of the card being taken hold of again.
class _TouchGate extends SingleChildRenderObjectWidget {
  final CardTransition transition;

  const _TouchGate({required this.transition, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTouchGate(transition);

  @override
  void updateRenderObject(BuildContext context, _RenderTouchGate render) =>
      render.transition = transition;
}

class _RenderTouchGate extends RenderProxyBox {
  _RenderTouchGate(this.transition);

  CardTransition transition;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (transition.passTouch()) return false;
    return super.hitTest(result, position: position);
  }
}

class _OpenCardRender extends SingleChildRenderObjectWidget {
  final CardTransition transition;
  final Color background;

  const _OpenCardRender({
    required this.transition,
    required this.background,
    super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderOpenCard(transition)..background = background;

  @override
  void updateRenderObject(BuildContext context, _RenderOpenCard render) =>
      render
        ..transition = transition
        ..background = background;
}

class _RenderOpenCard extends RenderProxyBox {
  _RenderOpenCard(this._transition);

  Color background = const Color(0x00000000);

  CardTransition _transition;
  set transition(CardTransition value) {
    if (value == _transition) return;
    if (attached) _transition.removeListener(markNeedsPaint);
    _transition = value;
    if (attached) _transition.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _transition.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _transition.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  bool get alwaysNeedsCompositing => true;

  bool get _open => _transition.phase == TransitionPhase.open;

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    if (_open) return context.paintChild(child, offset);
    final t = _transition;
    final origin = localToGlobal(Offset.zero);
    Rect local(Rect global) => global.shift(offset - origin);
    final picked = local(t.pickedRect);
    final drawn = local(t.detailsCard);
    // Where the details draw their card, onto where the card is now.
    final scale = picked.width / drawn.width;
    final move = Matrix4.translationValues(picked.left, picked.top, 0)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-drawn.left, -drawn.top, 0, 1);
    // Shown: the card, and under it the details on the page's colour,
    // down to the card below (in front of them both, as in the stack).
    // Above the card there is nothing: the details' bar and background
    // only come once it is open.
    final reveal = t.revealLine + offset.dy - origin.dy;
    final above = Rect.fromLTRB(
      offset.dx,
      offset.dy,
      offset.dx + size.width,
      reveal,
    );
    // Closing, what is under the card fades into the page in the first
    // half of the card's way back, instead of staying until the cards
    // below have risen past it: the card lands alone. Quick, as the details
    // move with their card (scrolled, they come down from above with it).
    // (The page's colour laid over them: the details are one layer, drawn
    // once.)
    final under = t.phase == TransitionPhase.closing
        ? ((t.progress(t.snapshot.picked) - 0.5) / 0.5).clamp(0.0, 1.0)
        : 1.0;
    void draw(PaintingContext context, Offset _) {
      // A little past the card below's top: behind its rounded corners.
      final bandEnd = reveal + 40;
      final below = Rect.fromLTRB(
        offset.dx,
        picked.bottom - 1,
        offset.dx + size.width,
        bandEnd,
      );
      if (bandEnd > picked.bottom) {
        context.canvas.drawRect(below, Paint()..color = background);
      }
      context.pushTransform(
        needsCompositing,
        Offset.zero,
        move,
        (context, _) => context.paintChild(child, offset),
      );
      // From the card's edge, not over it.
      if (under < 1 && bandEnd > picked.bottom) {
        context.canvas.drawRect(
          Rect.fromLTRB(below.left, picked.bottom, below.right, bandEnd),
          Paint()..color = background.withValues(alpha: 1 - under),
        );
      }
    }

    // The card below is rounded at its top: beside its corners the card
    // and the details still show (a straight cut there left notches).
    final next = t.nextCard;
    if (next == null || reveal >= offset.dy + size.height) {
      context.pushClipRect(needsCompositing, Offset.zero, above, draw);
      return;
    }
    final card = local(next);
    final r = CredentialCardArt.radiusFor(card.width).topLeft;
    final shown = Path.combine(
      PathOperation.difference,
      Path()..addRect(
        Rect.fromLTRB(above.left, above.top, above.right, reveal + r.y),
      ),
      Path()..addRRect(RRect.fromRectAndCorners(card, topLeft: r, topRight: r)),
    );
    context.pushClipPath(
      needsCompositing,
      Offset.zero,
      offset & size,
      shown,
      draw,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) =>
      _open && super.hitTest(result, position: position);
}

/// The header over the stack (title, search field): fades while a card
/// opens, comes back with the uppermost card.
class CardTransitionFade extends StatelessWidget {
  final Widget child;

  const CardTransitionFade({super.key, required this.child});

  // It lies on the page: it fades by the page's colour painted over it,
  // without a layer of its own.
  @override
  Widget build(BuildContext context) => CardTransitionFollow(
    opacity: (t) => t.headerOpacity,
    fadeTo: YiviPalette.of(context).background,
    child: child,
  );
}

/// The tab bar: goes down off the screen while a card opens, up again as
/// it closes, with the card. Only just off the screen ([distance], as in
/// the prototype): from further down it would come back in sight only as
/// the card lands, after everything else.
class CardTransitionDrop extends StatelessWidget {
  static const double distance = 160;

  final Widget child;

  const CardTransitionDrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) => CardTransitionFollow(
    offset: (t) =>
        Offset(0, distance * t.progress(t.snapshot.picked).clamp(0.0, 1.0)),
    child: child,
  );
}

/// A card of the stack while a card opens or closes: above the open one it
/// sinks into the page, below it it falls away, and the open one itself is
/// not drawn (its details draw it).
class StackCardFollow extends StatelessWidget {
  /// Its place in the stack.
  final int index;

  /// The card's width (its corners).
  final double width;
  final Widget child;

  const StackCardFollow({
    super.key,
    required this.index,
    required this.width,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    CardPose pose(CardTransition t) => index < t.snapshot.count
        ? t.choreography.pose(index, t.progress(index))
        : CardPose.rest;
    return CardTransitionFollow(
      opacity: (t) => index == t.snapshot.picked ? 0 : pose(t).opacity,
      offset: (t) =>
          Offset(0, index > t.snapshot.picked ? t.fall(index) : pose(t).dy),
      scale: (t) => pose(t).scale,
      darken: (t) => pose(t).darken,
      // Sinks into the page.
      fadeTo: YiviPalette.of(context).background,
      corner: CredentialCardArt.radiusFor(width).topLeft,
      child: child,
    );
  }
}

/// Draws [child] faded, moved, scaled (about its top centre), darkened and
/// turned (about its centre, in radians) as
/// the running card transition says, on every frame of it, without building
/// it again: it only paints. Without a transition it draws [child] as is.
class CardTransitionFollow extends StatelessWidget {
  final double Function(CardTransition t)? opacity;
  final Offset Function(CardTransition t)? offset;
  final double Function(CardTransition t)? turn;
  final double Function(CardTransition t)? scale;

  /// How dark (0 to 1).
  final double Function(CardTransition t)? darken;

  /// Fades by this colour (what is behind it) painted over it, instead of
  /// in a layer of its own.
  final Color? fadeTo;

  /// The corners of what is painted over it (fading, darkening).
  final Radius? corner;

  /// What [scale] scales about (the top centre by default).
  final Alignment scaleOrigin;
  final Widget child;

  const CardTransitionFollow({
    this.corner,
    this.scaleOrigin = Alignment.topCenter,
    super.key,
    this.opacity,
    this.offset,
    this.turn,
    this.scale,
    this.darken,
    this.fadeTo,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scope = CardTransitionScope.maybeOf(context);
    if (scope == null) return child;
    // Rebuilds only when a transition starts or ends.
    return ValueListenableBuilder<CardTransition?>(
      valueListenable: scope.current,
      builder: (context, t, child) => _FollowRender(
        transition: t,
        opacity: opacity,
        offset: offset,
        turn: turn,
        scale: scale,
        darken: darken,
        fadeTo: fadeTo,
        corner: corner,
        scaleOrigin: scaleOrigin,
        child: child,
      ),
      // Kept as a finished picture: only moved and faded per frame.
      child: RepaintBoundary(child: child),
    );
  }
}

class _FollowRender extends SingleChildRenderObjectWidget {
  final CardTransition? transition;
  final double Function(CardTransition t)? opacity;
  final Offset Function(CardTransition t)? offset;
  final double Function(CardTransition t)? turn;
  final double Function(CardTransition t)? scale;
  final double Function(CardTransition t)? darken;
  final Color? fadeTo;
  final Radius? corner;
  final Alignment scaleOrigin;

  const _FollowRender({
    required this.corner,
    required this.scaleOrigin,
    required this.transition,
    required this.opacity,
    required this.offset,
    required this.turn,
    required this.scale,
    required this.darken,
    required this.fadeTo,
    super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    final render = _RenderFollow(transition);
    updateRenderObject(context, render);
    return render;
  }

  @override
  void updateRenderObject(BuildContext context, _RenderFollow render) => render
    ..transition = transition
    ..opacityOf = opacity
    ..offsetOf = offset
    ..turnOf = turn
    ..scaleOf = scale
    ..darkenOf = darken
    ..fadeTo = fadeTo
    ..corner = corner
    ..scaleOrigin = scaleOrigin;
}

class _RenderFollow extends RenderProxyBox {
  _RenderFollow(this._transition);

  double Function(CardTransition t)? opacityOf;
  Offset Function(CardTransition t)? offsetOf;
  double Function(CardTransition t)? turnOf;
  double Function(CardTransition t)? scaleOf;
  double Function(CardTransition t)? darkenOf;
  Color? fadeTo;

  Radius? corner;
  Alignment scaleOrigin = Alignment.topCenter;

  CardTransition? _transition;
  set transition(CardTransition? value) {
    if (value == _transition) return;
    if (attached) _transition?.removeListener(markNeedsPaint);
    _transition = value;
    if (attached) _transition?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _transition?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _transition?.removeListener(markNeedsPaint);
    super.detach();
  }

  // Its own layer: repainting it each frame repaints only itself, and its
  // child (a repaint boundary below) is not drawn again.
  @override
  bool get isRepaintBoundary => true;

  @override
  bool get alwaysNeedsCompositing => _transition != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    final t = _transition;
    if (child == null) return;
    if (t == null) return context.paintChild(child, offset);
    final shift = offsetOf?.call(t) ?? Offset.zero;
    final alpha = ((opacityOf?.call(t) ?? 1) * 255).round().clamp(0, 255);
    final turn = turnOf?.call(t) ?? 0;
    final scale = scaleOf?.call(t) ?? 1;
    final darken = (darkenOf?.call(t) ?? 0).clamp(0.0, 1.0);
    if (alpha == 0) return;
    // Faded and darkened by what is painted over it, without a layer of
    // its own: the page's colour, and black.
    final fade = fadeTo != null ? 1 - alpha / 255 : 0.0;
    void over(Canvas canvas, Offset o) {
      if (darken == 0 && fade == 0) return;
      final box = (o + shift) & size;
      void fill(Color color) => corner == null
          ? canvas.drawRect(box, Paint()..color = color)
          : canvas.drawRRect(
              RRect.fromRectAndRadius(box, corner!),
              Paint()..color = color,
            );
      if (darken > 0) fill(Colors.black.withValues(alpha: darken));
      if (fade > 0) fill(fadeTo!.withValues(alpha: fade));
    }

    void place(PaintingContext context, Offset o) {
      void paint(PaintingContext context, Offset _) {
        context.paintChild(child, o + shift);
        over(context.canvas, o);
      }

      if (scale == 1) return paint(context, o);
      final top = o + shift + scaleOrigin.alongSize(size);
      context.pushTransform(
        needsCompositing,
        Offset.zero,
        Matrix4.translationValues(top.dx, top.dy, 0)
          ..scaleByDouble(scale, scale, 1, 1)
          ..translateByDouble(-top.dx, -top.dy, 0, 1),
        paint,
      );
    }

    void draw(PaintingContext context, Offset o) {
      if (turn == 0) return place(context, o);
      final c = size.center(o);
      context.pushTransform(
        needsCompositing,
        Offset.zero,
        Matrix4.translationValues(c.dx, c.dy, 0)
          ..rotateZ(turn)
          ..translateByDouble(-c.dx, -c.dy, 0, 1),
        place,
      );
    }

    if (alpha == 255 || fadeTo != null) return draw(context, offset);
    context.pushOpacity(offset, alpha, draw);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      _transition == null && super.hitTestChildren(result, position: position);
}

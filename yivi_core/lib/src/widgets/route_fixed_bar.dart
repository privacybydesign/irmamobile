import "package:flutter/rendering.dart";
import "package:material_ui/material_ui.dart";

import "../util/adaptive_layout.dart";

/// How a page's bar takes part in a push, as on iOS: the bar does not move
/// with its page; its buttons hand over in place to the next page's and its
/// title slides a little and fades ([RouteFixedBar]).
@immutable
class BarRole {
  /// The bar's buttons, on the transition's time (not its curve, which is
  /// most of the way in its first frames): in over the first 70 % of the
  /// page's push, out over the last 70 % of the next page's. A button that
  /// goes (popping to a page without it) so fades all along and is gone
  /// just as the page is; one on both pages (back to back) overlaps and
  /// stays nearly solid.
  final double buttons;

  /// The title: it comes 90 pt from the right as its page comes in, and
  /// goes 90 pt to the left as the next one covers it.
  final double titleOpacity;
  final double titleShift;

  const BarRole({this.buttons = 1, this.titleOpacity = 1, this.titleShift = 0});

  static const still = BarRole();

  /// The role of the bar of [route] now, from its two animations.
  factory BarRole.of(ModalRoute<dynamic> route) {
    double iv(double v, double a, double b) =>
        ((v - a) / (b - a)).clamp(0.0, 1.0);
    final pushed = route is PageRoute && !route.fullscreenDialog;
    final a = pushed
        ? Curves.fastEaseInToSlowEaseOut.transform(route.animation!.value)
        : 1.0;
    // Only a push over this page runs it (a dialog, a sheet or a rising
    // flow does not).
    final b = Curves.fastEaseInToSlowEaseOut.transform(
      route.secondaryAnimation!.value,
    );
    final aTime = pushed ? route.animation!.value : 1.0;
    final bTime = route.secondaryAnimation!.value;
    return BarRole(
      buttons: iv(aTime, 0, 0.7) * (1 - iv(bTime, 0.3, 1)),
      titleOpacity: iv(a, 0.35, 1) * (1 - iv(b, 0, 0.5)),
      titleShift: 90 * (1 - a) - 90 * b,
    );
  }
}

/// Keeps a page's bar ([child]) where it is while its page is pushed or
/// popped, or covered by the next page's push: it is drawn where it would
/// be without the page's transition (the slide on iOS, the predictive back
/// on Android), so only the content moves. [builder] gets the bar's
/// [BarRole] for its buttons and title.
///
/// Not on a tablet (pages there are sheets), with Reduce motion (pages
/// cross-fade), or while the page rises as a flow of its own.
class RouteFixedBar extends StatelessWidget {
  final Widget Function(BuildContext context, BarRole role) builder;

  const RouteFixedBar({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null ||
        route.animation == null ||
        route.secondaryAnimation == null ||
        isExpandedLayout(context) ||
        MediaQuery.disableAnimationsOf(context)) {
      return builder(context, BarRole.still);
    }
    final pushed = route is PageRoute && !route.fullscreenDialog;
    return AnimatedBuilder(
      animation: Listenable.merge([route.animation, route.secondaryAnimation]),
      builder: (context, _) {
        final moving =
            (pushed && route.animation!.value < 1) ||
            route.secondaryAnimation!.value > 0;
        // The page: laid out after this bar first builds, so found here.
        final anchor = moving
            ? context
                  .findAncestorStateOfType<ScaffoldState>()
                  ?.context
                  .findRenderObject()
            : null;
        return _Unmoved(
          anchor: moving && anchor is RenderBox ? anchor : null,
          tick: route.animation!.value + 2 * route.secondaryAnimation!.value,
          child: builder(context, moving ? BarRole.of(route) : BarRole.still),
        );
      },
    );
  }
}

/// Draws its child where it would be if [anchor] (the page) were not moved
/// by its route's transition. Its own layer, so redrawing it on every frame
/// of a push does not redraw the page.
class _Unmoved extends SingleChildRenderObjectWidget {
  final RenderBox? anchor;
  final double tick;

  const _Unmoved({required this.anchor, required this.tick, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderUnmoved(anchor, tick);

  @override
  void updateRenderObject(BuildContext context, _RenderUnmoved render) => render
    ..anchor = anchor
    ..tick = tick;
}

class _RenderUnmoved extends RenderProxyBox {
  _RenderUnmoved(this._anchor, this._tick);

  RenderBox? _anchor;
  set anchor(RenderBox? value) {
    if (value == _anchor) return;
    _anchor = value;
    markNeedsPaint();
  }

  double _tick;
  set tick(double value) {
    if (value == _tick) return;
    _tick = value;
    markNeedsPaint();
  }

  @override
  bool get isRepaintBoundary => true;

  /// From this box to where it would be with the page at rest, or null.
  Matrix4? _correction() {
    final anchor = _anchor;
    if (anchor == null || !anchor.attached || !attached) return null;
    // The page at rest fills the screen from its top left corner.
    final atRest = getTransformTo(anchor);
    final now = getTransformTo(null);
    if (now.invert() == 0) return null;
    return now..multiply(atRest);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    final correction = _correction();
    if (correction == null) {
      context.paintChild(child, offset);
      return;
    }
    context.pushTransform(
      needsCompositing,
      offset,
      correction,
      (context, offset) => context.paintChild(child, offset),
    );
  }

  // Where it is drawn, for positions, hit tests and semantics.
  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final correction = _correction();
    if (correction != null) transform.multiply(correction);
  }

  // Not while the page moves under it.
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) =>
      _anchor == null && super.hitTest(result, position: position);
}

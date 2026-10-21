import "dart:ui";

import "package:flutter/foundation.dart";
import "package:flutter/rendering.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";
import "glass_surface.dart";

/// How far content has scrolled under a bar, from 0 (nothing under it) to 1
/// (a few points or more). Feed it the notifications of the scroll view
/// under the bar, with [ScrollEdgeListener] or [handle].
class ScrollEdgeNotifier extends ValueNotifier<double> {
  ScrollEdgeNotifier() : super(0);

  /// Over this many points of scrolling the edge comes in, so it follows a
  /// slow drag instead of switching.
  static const ramp = 6.0;

  static double valueOf(ScrollMetrics metrics) =>
      ((metrics.pixels - metrics.minScrollExtent) / ramp).clamp(0.0, 1.0);

  /// Takes the vertical scroll view right under the listener into account,
  /// not lists nested in it or sideways ones. Never stops the notification.
  bool handle(Notification notification) {
    final (metrics, depth) = switch (notification) {
      ScrollNotification(:final metrics, :final depth) => (metrics, depth),
      ScrollMetricsNotification(:final metrics, :final depth) => (
        metrics,
        depth,
      ),
      _ => (null, 0),
    };
    if (metrics == null || depth != 0 || metrics.axis != Axis.vertical) {
      return false;
    }
    value = valueOf(metrics);
    return false;
  }
}

/// Feeds the scroll position of [child]'s scroll view to [notifier].
class ScrollEdgeListener extends StatelessWidget {
  final ScrollEdgeNotifier notifier;
  final Widget child;

  const ScrollEdgeListener({
    super.key,
    required this.notifier,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => NotificationListener<Notification>(
    onNotification: notifier.handle,
    child: child,
  );
}

/// The edge under a bar once content scrolls under it, as the "hard" scroll
/// edge of iOS 27: from the top of the screen (or sheet) down to the bar's
/// bottom, the content under it is blurred and mostly covered by
/// [color], and a hairline marks where the bar ends. With nothing under
/// the bar there is no band and no line.
///
/// Measured on iOS 27: content shows through at about 30 % (light) to 40 %
/// (dark), the edge is sharp, and its line is black at 10 % (light) or
/// white at 13 % (dark), one pixel thick.
///
/// Fills the space its parent gives it; put it behind the bar's content.
/// [under] is how far content is under the bar (see [ScrollEdgeNotifier]);
/// [opacity] fades the whole edge with the bar (it is passed to the blur and
/// colours, not put in an [Opacity], which would darken the blur).
class ScrollEdgeBand extends StatelessWidget {
  final ValueListenable<double> under;

  /// The colour the content fades to: the screen's background by default,
  /// the sheet's for a sheet.
  final Color? color;
  final double opacity;

  const ScrollEdgeBand({
    super.key,
    required this.under,
    this.color,
    this.opacity = 1,
  });

  static const double _blur = 12;
  static const double _cover = 0.7;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ValueListenableBuilder<double>(
      valueListenable: under,
      builder: (context, value, _) => _band(context, value * opacity),
    ),
  );

  Widget _band(BuildContext context, double t) {
    if (t <= 0) return const SizedBox.expand();
    final palette = YiviPalette.of(context);
    final solid = MediaQuery.highContrastOf(context);
    // Under an open sheet nothing of it shows: no blur to redo every frame.
    final blur = !GlassScope.coveredOf(context);
    final base = color ?? palette.background;
    // In dark mode the frost is a shade lighter than the page, as on iOS.
    final fill = palette.isDark ? Color.lerp(base, Colors.white, 0.03)! : base;
    final line = palette.isDark
        ? const Color(0x21FFFFFF)
        : const Color(0x1A000000);
    final band = DecoratedBox(
      key: const Key("scroll_edge_band"),
      decoration: BoxDecoration(
        color: fill.withValues(alpha: fill.a * (solid ? 1 : _cover) * t),
        border: Border(
          bottom: BorderSide(
            color: line.withValues(alpha: line.a * t),
            width: 1 / MediaQuery.devicePixelRatioOf(context),
          ),
        ),
      ),
      child: const SizedBox.expand(),
    );
    if (solid || !blur) return band;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blur * t, sigmaY: _blur * t),
        child: band,
      ),
    );
  }
}

/// Lays out [bar] above [body] like a column, but paints [body] first, so
/// that its content keeps painting upwards as it scrolls, under [bar] (which
/// can then put a [ScrollEdgeBand] behind its content). [body] is clipped
/// at its bottom only.
///
/// With [expand] the body fills the rest of the height (a page of fixed
/// height); without, it takes what it needs, up to the rest (a sheet that
/// fits its content).
class BarOverBody extends MultiChildRenderObjectWidget {
  BarOverBody({
    super.key,
    required Widget bar,
    required Widget body,
    this.expand = true,
  }) : super(
         children: [
           _OpenTop(child: body),
           bar,
         ],
       );

  final bool expand;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderBarOverBody(expand: expand);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderBarOverBody renderObject,
  ) {
    renderObject.expand = expand;
  }
}

/// Clips its child at the bottom and the sides, not at the top.
class _OpenTop extends StatelessWidget {
  final Widget child;

  const _OpenTop({required this.child});

  @override
  Widget build(BuildContext context) =>
      ClipRect(clipper: const _OpenTopClipper(), child: child);
}

class _OpenTopClipper extends CustomClipper<Rect> {
  const _OpenTopClipper();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-size.width, -100000, size.width * 2, size.height);

  @override
  bool shouldReclip(_OpenTopClipper oldClipper) => false;
}

class _BarOverBodyData extends ContainerBoxParentData<RenderBox> {}

/// The render object of [BarOverBody].
class RenderBarOverBody extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _BarOverBodyData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _BarOverBodyData> {
  RenderBarOverBody({required bool expand}) : _expand = expand;

  bool _expand;
  set expand(bool value) {
    if (value == _expand) return;
    _expand = value;
    markNeedsLayout();
  }

  RenderBox get _body => firstChild!;
  RenderBox get _bar => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _BarOverBodyData) {
      child.parentData = _BarOverBodyData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => [
    _body.getMinIntrinsicWidth(height),
    _bar.getMinIntrinsicWidth(height),
  ].reduce((a, b) => a > b ? a : b);

  @override
  double computeMaxIntrinsicWidth(double height) => [
    _body.getMaxIntrinsicWidth(height),
    _bar.getMaxIntrinsicWidth(height),
  ].reduce((a, b) => a > b ? a : b);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _bar.getMinIntrinsicHeight(width) + _body.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _bar.getMaxIntrinsicHeight(width) + _body.getMaxIntrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final barHeight = _bar
        .getDryLayout(BoxConstraints.tightFor(width: width))
        .height;
    final rest = (constraints.maxHeight - barHeight).clamp(
      0.0,
      double.infinity,
    );
    final bodyHeight = _expand && rest.isFinite
        ? rest
        : _body
              .getDryLayout(
                BoxConstraints(
                  minWidth: width,
                  maxWidth: width,
                  maxHeight: rest,
                ),
              )
              .height;
    return constraints.constrain(Size(width, barHeight + bodyHeight));
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    _bar.layout(BoxConstraints.tightFor(width: width), parentUsesSize: true);
    final barHeight = _bar.size.height;
    final rest = (constraints.maxHeight - barHeight).clamp(
      0.0,
      double.infinity,
    );
    _body.layout(
      _expand && rest.isFinite
          ? BoxConstraints.tightFor(width: width, height: rest)
          : BoxConstraints(minWidth: width, maxWidth: width, maxHeight: rest),
      parentUsesSize: true,
    );
    (_bar.parentData! as _BarOverBodyData).offset = Offset.zero;
    (_body.parentData! as _BarOverBodyData).offset = Offset(0, barHeight);
    size = constraints.constrain(Size(width, barHeight + _body.size.height));
  }

  // Children are [body, bar]: painted in that order, hit from the bar down.
  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// A page whose content scrolls under a bar on top of it: the one way the
/// app puts the hard scroll edge ([ScrollEdgeBand]) under a bar. [child] is
/// the page (its scroll view tells whether content is under the bar), the
/// edge goes from the top down to [height], and [bar] (positioned children)
/// is drawn over the edge.
///
/// Without [bar] and [height] it is a page without a bar: the edge sits
/// under the status bar, as iOS does for a scroll view at the top of the
/// screen.
///
/// The sheets (GlassSheetPage) and IrmaAppBar draw the same band, fitted
/// into their own layout.
class ScrollEdge extends StatefulWidget {
  final Widget child;

  /// How far down the edge goes: the bar's bottom. Null: the status bar.
  final double? height;

  /// The bar's content, over the edge, as children of a [Stack].
  final List<Widget> bar;

  /// Draws the band, for one that moves or fades with its bar; by default a
  /// plain [ScrollEdgeBand].
  final Widget Function(BuildContext context, ValueListenable<double> under)?
  band;

  const ScrollEdge({
    super.key,
    required this.child,
    this.height,
    this.bar = const [],
    this.band,
  });

  @override
  State<ScrollEdge> createState() => _ScrollEdgeState();
}

class _ScrollEdgeState extends State<ScrollEdge> {
  final _under = ScrollEdgeNotifier();

  @override
  void dispose() {
    _under.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: ScrollEdgeListener(notifier: _under, child: widget.child),
      ),
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: widget.height ?? MediaQuery.paddingOf(context).top,
        child:
            widget.band?.call(context, _under) ?? ScrollEdgeBand(under: _under),
      ),
      ...widget.bar,
    ],
  );
}

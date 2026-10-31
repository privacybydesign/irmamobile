import "dart:math";

import "package:flutter/foundation.dart" show listEquals;
import "package:material_ui/material_ui.dart";

import "../../theme/yivi_motion.dart";
import "../../theme/yivi_palette.dart";

/// The surface of what floats over the page (the tab bar, a menu, a toast,
/// a round button) or holds a sheet: solid, in the surface colour, with a
/// thin edge and, as it floats, a soft shadow. No glass: the same on iOS and
/// Android, and nothing to blur on every frame.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final ShapeBorder shape;
  final EdgeInsetsGeometry? padding;

  /// Replaces the surface colour, e.g. for a tinted chip or the sheet.
  final Color? fill;

  /// Fades the surface in or out: its fill, edge and shadow, and [child].
  final double opacity;

  /// Over a camera picture or a photo: dark, in either theme. Give its
  /// content white.
  final bool dark;

  /// The thin edge round it; off for content that fills it edge to edge in
  /// a dark colour.
  final bool rim;

  const GlassSurface({
    super.key,
    required this.child,
    this.shape = const StadiumBorder(),
    this.padding,
    this.fill,
    this.opacity = 1,
    this.dark = false,
    this.rim = true,
  });

  /// The fill and edge of a [dark] surface.
  static const darkFill = Color(0xFF282C32);
  static const darkRim = Color(0x29FFFFFF);

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final a = opacity.clamp(0.0, 1.0);
    Color fade(Color c) => a == 1 ? c : c.withValues(alpha: c.a * a);
    final surface = fill ?? (dark ? darkFill : palette.surface);
    final edge = dark ? darkRim : palette.divider;
    final padded = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: a == 1 ? child : Opacity(opacity: a, child: child),
    );
    return CustomPaint(
      painter: _OuterShadowPainter(
        shape: shape,
        // Nothing shows through a solid surface: the shadow may be under it.
        under: surface.a == 1 && a == 1,
        shadows: [
          BoxShadow(
            color: fade(palette.glassShadow),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: palette.glassShadow.withValues(alpha: 0.06 * a),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: DecoratedBox(
          decoration: ShapeDecoration(shape: shape, color: fade(surface)),
          child: DecoratedBox(
            // The edge in front, so content under it keeps a crisp line.
            decoration: ShapeDecoration(
              shape: rim ? _withSide(shape, fade(edge)) : shape,
            ),
            position: DecorationPosition.foreground,
            child: padded,
          ),
        ),
      ),
    );
  }

  static ShapeBorder _withSide(ShapeBorder shape, Color color) {
    final side = BorderSide(color: color);
    return switch (shape) {
      StadiumBorder() => StadiumBorder(side: side),
      CircleBorder() => CircleBorder(side: side),
      RoundedRectangleBorder(:final borderRadius) => RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: side,
      ),
      _ => shape,
    };
  }
}

/// Paints [shadows] around [shape], and not under it unless [under]: a
/// shadow under a see-through fill would show through it.
///
/// Cheap to draw: each shadow is a blurred rounded rectangle, which the
/// renderer draws directly, where a blurred path is blurred in a layer of
/// its own, over its whole size, on every frame. On a mid-range Android
/// phone the path shadow of a sheet cost more than everything else on
/// screen.
class _OuterShadowPainter extends CustomPainter {
  _OuterShadowPainter({
    required this.shape,
    required this.shadows,
    this.under = false,
  });

  final ShapeBorder shape;
  final List<BoxShadow> shadows;
  final bool under;

  /// [shape] in [rect] as a rounded rectangle, or null for another shape.
  RRect? _rrect(Rect rect) => switch (shape) {
    StadiumBorder() => RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.shortestSide / 2),
    ),
    CircleBorder() => RRect.fromRectAndRadius(
      Rect.fromCircle(center: rect.center, radius: rect.shortestSide / 2),
      Radius.circular(rect.shortestSide / 2),
    ),
    RoundedRectangleBorder(:final borderRadius) =>
      borderRadius.resolve(TextDirection.ltr).toRRect(rect),
    _ => null,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (!under) {
      final reach = shadows.fold<double>(
        0,
        (r, s) => max(r, s.blurSigma * 3 + s.offset.distance + s.spreadRadius),
      );
      canvas
        ..save()
        ..clipPath(
          Path.combine(
            PathOperation.difference,
            Path()..addRect(rect.inflate(reach + 1)),
            shape.getOuterPath(rect),
          ),
        );
    }
    for (final shadow in shadows) {
      final at = rect.shift(shadow.offset).inflate(shadow.spreadRadius);
      final rrect = _rrect(at);
      if (rrect != null) {
        canvas.drawRRect(rrect, shadow.toPaint());
      } else {
        canvas.drawPath(shape.getOuterPath(at), shadow.toPaint());
      }
    }
    if (!under) canvas.restore();
  }

  @override
  bool shouldRepaint(_OuterShadowPainter old) =>
      old.shape != shape ||
      old.under != under ||
      !listEquals(old.shadows, shadows);
}

/// Grows (or shrinks) its child slightly while pressed.
class _PressScale extends StatefulWidget {
  final Widget child;
  final double scale;

  const _PressScale({required this.child, required this.scale});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  // The pointer can lift after the button is gone, e.g. when a pull on the
  // card closes the sheet it is in.
  void _press(bool down) {
    if (mounted && down != _down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: (_) => _press(true),
      onPointerUp: (_) => _press(false),
      onPointerCancel: (_) => _press(false),
      child: AnimatedScale(
        scale: _down && !reduceMotion ? widget.scale : 1,
        duration: const Duration(milliseconds: 220),
        curve: YiviMotion.ease,
        child: widget.child,
      ),
    );
  }
}

/// How a button answers a press, for buttons outside this file: glass grows
/// ([glass]), a button gives way ([button]), a card a little less ([card]).
class PressScale extends StatelessWidget {
  /// Glass buttons, glass pills and tags, as on iOS.
  static const glass = 1.08;

  /// Pills, links, plain icons, tabs.
  static const button = 0.97;

  /// Cards and card-sized spots.
  static const card = 0.98;

  final Widget child;
  final double scale;

  /// A disabled button does not move.
  final bool enabled;

  const PressScale({
    super.key,
    required this.child,
    this.scale = button,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) =>
      enabled ? _PressScale(scale: scale, child: child) : child;
}

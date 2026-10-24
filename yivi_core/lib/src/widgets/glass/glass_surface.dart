import "dart:math";
import "dart:ui";

import "package:flutter/foundation.dart" show listEquals;
import "package:material_ui/material_ui.dart";

import "../../theme/yivi_motion.dart";
import "../../theme/yivi_palette.dart";

/// Where blur under it can be seen. The blur is the most expensive thing the
/// app draws: Flutter redoes it on every frame, for every piece of glass. So
/// it is off where it can't be seen:
/// - [blur] false: glass on a sheet, whose colour is flat;
/// - [covered]: the page under an open sheet, glass and scroll edges both
///   (see GlassSheetCover).
class GlassScope extends InheritedWidget {
  final bool blur;
  final bool covered;

  const GlassScope({
    super.key,
    this.blur = true,
    this.covered = false,
    required super.child,
  });

  static GlassScope? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassScope>();

  /// Whether glass here blurs what is behind it.
  static bool blurOf(BuildContext context) {
    if (GlassOpaque.of(context)) return false;
    final scope = _of(context);
    return scope == null || (scope.blur && !scope.covered);
  }

  /// Whether a sheet covers this page.
  static bool coveredOf(BuildContext context) => _of(context)?.covered ?? false;

  @override
  bool updateShouldNotify(GlassScope oldWidget) =>
      oldWidget.blur != blur || oldWidget.covered != covered;
}

/// The developer setting "Opaque glass": every piece of glass, scroll edges
/// included, is drawn in its own colour over the page, not see-through and
/// without blur, to feel on a device what the glass costs. Set once around
/// the app's pages, above any [GlassScope], so a sheet's own scope doesn't
/// undo it.
class GlassOpaque extends InheritedWidget {
  final bool opaque;

  const GlassOpaque({super.key, required this.opaque, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassOpaque>()?.opaque ??
      false;

  @override
  bool updateShouldNotify(GlassOpaque oldWidget) => oldWidget.opaque != opaque;
}

/// Frosted glass: a blurred, translucent fill with a light inner edge and a
/// soft shadow. Turns into a solid surface when the platform asks for less
/// transparency (high contrast), so text on it always stays readable.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final ShapeBorder shape;
  final EdgeInsetsGeometry? padding;

  /// Replaces the glass fill, e.g. for the tinted QR button.
  final Color? fill;

  /// Blurs what is behind it; by default as its [GlassScope] says.
  final bool? blur;

  /// Fades the glass in or out. Use this instead of an [Opacity] or a
  /// [FadeTransition] around it: inside their offscreen layer the blur
  /// samples that empty layer, so the glass looks dark until the fade ends
  /// and then jumps to its real look. Here the fill, edge, shadow and blur
  /// strength fade, and only [child] goes through an opacity layer.
  final double opacity;

  /// Dark glass, for a camera picture or a photo: a smoky fill with a faint
  /// rim and no light sheen, in either theme. Give its content white.
  final bool dark;

  /// The light edge round the glass; off for content that fills it edge to
  /// edge in a dark colour.
  final bool rim;

  const GlassSurface({
    super.key,
    required this.child,
    this.shape = const StadiumBorder(),
    this.padding,
    this.fill,
    this.opacity = 1,
    this.blur,
    this.dark = false,
    this.rim = true,
  });

  /// The fill and rim of [dark] glass.
  static const darkFill = Color(0x8C282C32);
  static const darkRim = Color(0x29FFFFFF);

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final solid = MediaQuery.highContrastOf(context);
    final opaque = GlassOpaque.of(context);
    final a = opacity.clamp(0.0, 1.0);
    Color fade(Color c) => a == 1 ? c : c.withValues(alpha: c.a * a);
    final glassFill =
        fill ??
        (dark
            ? (solid ? const Color(0xFF282C32) : darkFill)
            : (solid ? palette.surface : palette.glassFill));
    // Dark glass lies over a dark picture, not over the page.
    final under = dark ? Colors.black : palette.background;
    final edge = dark ? darkRim : palette.glassBorder;
    final sheen = dark ? 0.0 : (solid ? 0.0 : palette.glassHighlight.a * 0.35);

    final shaped = ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: _maybeBlur(
        solid: solid || opaque || !(blur ?? GlassScope.blurOf(context)),
        sigma: 18 * a,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: shape,
            // Opaque glass: its colour as it looks over the page.
            color: fade(
              opaque ? Color.alphaBlend(glassFill, under) : glassFill,
            ),
          ),
          position: DecorationPosition.background,
          child: DecoratedBox(
            // The soft sheen along the top that makes it read as glass. It
            // lies on the glass, behind the content: in front of it, it
            // veiled whatever sat in the top half (a sheet's logo and
            // heading came out washed out).
            decoration: ShapeDecoration(
              shape: shape,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  // A share of the theme's own highlight: a soft white
                  // sheen in light, only a faint one on dark glass (an
                  // absolute 35% white glowed there).
                  palette.glassHighlight.withValues(alpha: sheen * a),
                  palette.glassHighlight.withValues(alpha: 0),
                ],
                stops: const [0, 0.5],
              ),
            ),
            position: DecorationPosition.background,
            child: DecoratedBox(
              // The light edge, in front so content scrolling under it
              // keeps a crisp rim.
              decoration: ShapeDecoration(
                shape: rim ? _withSide(shape, fade(edge)) : shape,
              ),
              position: DecorationPosition.foreground,
              child: Padding(
                padding: padding ?? EdgeInsets.zero,
                child: a == 1 ? child : Opacity(opacity: a, child: child),
              ),
            ),
          ),
        ),
      ),
    );

    return CustomPaint(
      painter: _OuterShadowPainter(
        shape: shape,
        // Nothing shows through opaque glass: no need to keep the shadow
        // from under it.
        under: opaque || glassFill.a == 1,
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
      child: shaped,
    );
  }

  Widget _maybeBlur({
    required bool solid,
    required double sigma,
    required Widget child,
  }) {
    if (solid || sigma <= 0) return child;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
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

/// Paints [shadows] around [shape], and not under it unless [under]. A
/// shadow under translucent glass would show through it, and the blur would
/// pick it up, so the glass looked dark (a black slab in the dark theme)
/// wherever content scrolled underneath.
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

/// A round glass button with an icon, like the close and plus buttons.
class GlassIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final String semanticsLabel;
  final double size;

  /// Dark glass, for a live camera picture. Give it a white icon.
  final bool dark;

  /// Fades the button; see [GlassSurface.opacity].
  final double opacity;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticsLabel,
    this.size = 44,
    this.dark = false,
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    final a = opacity.clamp(0.0, 1.0);
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: IgnorePointer(
        ignoring: a == 0,
        child: _PressScale(
          scale: 1.08,
          child: GlassSurface(
            shape: const CircleBorder(),
            dark: dark,
            opacity: a,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                highlightColor: Colors.transparent,
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: SizedBox.square(
                  dimension: size,
                  child: Center(child: icon),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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

/// Exposes [_PressScale] for buttons outside this file.
class PressScale extends StatelessWidget {
  final Widget child;
  final double scale;

  const PressScale({super.key, required this.child, this.scale = 0.97});

  @override
  Widget build(BuildContext context) => _PressScale(scale: scale, child: child);
}

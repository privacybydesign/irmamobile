import "dart:ui";

import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";

/// Frosted glass: a blurred, translucent fill with a light inner edge and a
/// soft shadow. Turns into a solid surface when the platform asks for less
/// transparency (high contrast), so text on it always stays readable.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final ShapeBorder shape;
  final EdgeInsetsGeometry? padding;

  /// Replaces the glass fill, e.g. for the tinted QR button.
  final Color? fill;
  final bool shadow;

  const GlassSurface({
    super.key,
    required this.child,
    this.shape = const StadiumBorder(),
    this.padding,
    this.fill,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final solid = MediaQuery.highContrastOf(context);

    final shaped = ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: _maybeBlur(
        solid: solid,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: shape,
            color: fill ?? (solid ? palette.surface : palette.glassFill),
          ),
          position: DecorationPosition.background,
          child: DecoratedBox(
            // The light inner edge along the top that makes it read as glass.
            decoration: ShapeDecoration(
              shape: _withSide(shape, palette.glassBorder),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  palette.glassHighlight.withValues(alpha: solid ? 0 : 0.35),
                  palette.glassHighlight.withValues(alpha: 0),
                ],
                stops: const [0, 0.5],
              ),
            ),
            position: DecorationPosition.foreground,
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          ),
        ),
      ),
    );

    if (!shadow) return shaped;
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [
          BoxShadow(
            color: palette.glassShadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: palette.glassShadow.withValues(alpha: 0.06),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: shaped,
    );
  }

  Widget _maybeBlur({required bool solid, required Widget child}) {
    if (solid) return child;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
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
      RoundedSuperellipseBorder(:final borderRadius) =>
        RoundedSuperellipseBorder(borderRadius: borderRadius, side: side),
      _ => shape,
    };
  }
}

/// A round glass button with an icon, like the close and plus buttons.
class GlassIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final String semanticsLabel;
  final double size;
  final Color? fill;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticsLabel,
    this.size = 44,
    this.fill,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: _PressScale(
        scale: 1.08,
        child: GlassSurface(
          shape: const CircleBorder(),
          fill: fill,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
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
    );
  }
}

/// A glass pill with a text label, e.g. the "Done" button on the detail view.
class GlassPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Key? buttonKey;

  const GlassPillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return _PressScale(
      scale: 1.05,
      child: GlassSurface(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: buttonKey,
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    label,
                    style: palette.display(16).copyWith(color: palette.text),
                  ),
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

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down && !reduceMotion ? widget.scale : 1,
        duration: const Duration(milliseconds: 220),
        curve: const Cubic(0.2, 0.8, 0.2, 1),
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
  Widget build(BuildContext context) =>
      _PressScale(scale: scale, child: child);
}

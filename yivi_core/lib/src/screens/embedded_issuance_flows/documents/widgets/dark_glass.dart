import "dart:ui";

import "package:material_ui/material_ui.dart";

import "../../../../widgets/glass/glass_surface.dart";

/// The dark glass of the camera screens: a smoky, blurred surface with a thin
/// light edge, readable over any camera picture.
class DarkGlass extends StatelessWidget {
  final Widget child;
  final ShapeBorder shape;
  final EdgeInsetsGeometry padding;

  /// A colour instead of the smoke, e.g. green or red for a result.
  final Color? tint;

  const DarkGlass({
    super.key,
    required this.child,
    this.shape = const StadiumBorder(),
    this.padding = EdgeInsets.zero,
    this.tint,
  });

  static const fill = Color(0x6B1C1C1E);
  static const edge = Color(0x38FFFFFF);

  @override
  Widget build(BuildContext context) {
    final edged = switch (shape) {
      RoundedRectangleBorder(:final borderRadius) => RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: const BorderSide(color: edge),
      ),
      CircleBorder() => const CircleBorder(side: BorderSide(color: edge)),
      _ => const StadiumBorder(side: BorderSide(color: edge)),
    };
    // Opaque glass (developer setting): the smoke as it looks over black,
    // with no blur behind it.
    final opaque = GlassOpaque.of(context);
    final glass = DecoratedBox(
      decoration: ShapeDecoration(
        color: opaque
            ? Color.alphaBlend(tint ?? fill, Colors.black)
            : tint ?? fill,
        shape: edged,
      ),
      child: Padding(padding: padding, child: child),
    );
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: opaque
            ? glass
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: glass,
              ),
      ),
    );
  }
}

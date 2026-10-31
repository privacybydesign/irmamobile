import "package:material_ui/material_ui.dart";

/// The dark surface of the camera screens: solid, with a thin light edge,
/// readable over any camera picture.
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

  static const fill = Color(0xFF1C1C1E);
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
    final glass = DecoratedBox(
      decoration: ShapeDecoration(color: tint ?? fill, shape: edged),
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
        child: glass,
      ),
    );
  }
}

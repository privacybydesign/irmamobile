import "package:material_ui/material_ui.dart";

/// The dark surface of the camera screens: solid, with a thin light edge,
/// readable over any camera picture.
class DarkGlass extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  const DarkGlass({
    super.key,
    required this.child,
    required this.borderRadius,
    this.padding = EdgeInsets.zero,
  });

  static const _fill = Color(0xFF1C1C1E);
  static const _edge = Color(0x38FFFFFF);

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: borderRadius);
    final edged = RoundedRectangleBorder(
      borderRadius: borderRadius,
      side: const BorderSide(color: _edge),
    );
    final glass = DecoratedBox(
      decoration: ShapeDecoration(color: _fill, shape: edged),
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

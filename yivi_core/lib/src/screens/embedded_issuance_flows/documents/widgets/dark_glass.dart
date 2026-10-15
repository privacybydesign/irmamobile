import "dart:ui";

import "package:material_ui/material_ui.dart";

/// The dark glass of the camera screens: a smoky, blurred surface with a thin
/// light edge, readable over any camera picture.
class DarkGlass extends StatelessWidget {
  final Widget child;
  final ShapeBorder shape;
  final EdgeInsetsGeometry padding;

  const DarkGlass({
    super.key,
    required this.child,
    this.shape = const StadiumBorder(),
    this.padding = EdgeInsets.zero,
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
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: ShapeDecoration(color: fill, shape: edged),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// A round 44 pt dark glass button, like the back button over the camera.
class DarkGlassIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticsLabel;
  final VoidCallback onTap;

  const DarkGlassIconButton({
    super.key,
    required this.icon,
    required this.semanticsLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: DarkGlass(
        shape: const CircleBorder(),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.square(
              dimension: 44,
              child: Icon(icon, size: 22, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

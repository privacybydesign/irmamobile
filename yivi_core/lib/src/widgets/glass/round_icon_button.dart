import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";
import "glass_surface.dart";

/// The app's round icon button: close, back, add, search, the view menu, the
/// filter. Every one is this widget, [size] across (as iOS's round bar
/// buttons), solid: the surface's colour with a thin edge, as the home tabs'
/// bars. [dark] is the version over a camera picture or a photo. While
/// [count] is more than 0 (filters on) it is tinted, with the count in a
/// badge. It gives way a little under the finger.
class RoundIconButton extends StatelessWidget {
  static const double size = 44;

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// Over a camera picture or a photo: dark, with a white icon.
  final bool dark;

  /// Fades the button with what it sits on (a page's chrome).
  final double opacity;

  /// How many filters are on; 0 for none, or a button that has none.
  final int count;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.dark = false,
    this.opacity = 1,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final on = count > 0;
    final a = opacity.clamp(0.0, 1.0);
    final Color fill;
    final Color ink;
    final BorderSide edge;
    if (dark) {
      fill = Colors.black.withValues(alpha: 0.5);
      ink = Colors.white;
      edge = BorderSide(color: Colors.white.withValues(alpha: 0.16));
    } else if (on) {
      fill = palette.primary.withValues(alpha: palette.isDark ? 0.22 : 0.12);
      ink = palette.selectedTab;
      edge = BorderSide.none;
    } else {
      fill = palette.surface;
      ink = palette.text;
      edge = BorderSide(color: palette.divider);
    }
    final button = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: ShapeDecoration(
            color: fill,
            shape: CircleBorder(side: edge),
          ),
          child: Icon(icon, size: 22, color: ink),
        ),
        if (on)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20),
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: palette.primary,
                shape: StadiumBorder(
                  side: BorderSide(color: palette.background, width: 2),
                ),
              ),
              child: Text(
                "$count",
                style: palette
                    .body(11.5)
                    .copyWith(fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
      ],
    );
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: IgnorePointer(
        ignoring: a == 0,
        child: Opacity(
          opacity: a,
          child: PressScale(
            enabled: onTap != null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: button,
            ),
          ),
        ),
      ),
    );
  }
}

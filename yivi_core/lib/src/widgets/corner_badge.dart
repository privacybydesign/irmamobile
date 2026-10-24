import "package:material_ui/material_ui.dart";

/// A round badge with an icon, for the corner of a logo or a card: a check,
/// a trust mark, what a request does. With [ring] it is ringed in the colour
/// of what it sits on, so it stands out from the picture under it.
class CornerBadge extends StatelessWidget {
  final IconData icon;
  final Color fill;
  final double size;
  final double iconSize;
  final Color ink;
  final Color? ring;
  final double ringWidth;

  const CornerBadge({
    super.key,
    required this.icon,
    required this.fill,
    required this.size,
    required this.iconSize,
    this.ink = Colors.white,
    this.ring,
    this.ringWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final ring = this.ring;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: ring == null ? null : Border.all(color: ring, width: ringWidth),
      ),
      child: Icon(icon, size: iconSize, color: ink),
    );
  }
}

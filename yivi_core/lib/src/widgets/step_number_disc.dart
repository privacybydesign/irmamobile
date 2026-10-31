import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";

/// The number of a step in a list of numbered steps: [number] on a tinted
/// disc [size] across, in [style]. Hidden from screen readers; the step's
/// text says it all.
class StepNumberDisc extends StatelessWidget {
  final String number;
  final double size;
  final TextStyle style;

  const StepNumberDisc(
    this.number, {
    super.key,
    this.size = 26,
    required this.style,
  });

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: YiviPalette.of(context).tint,
        shape: BoxShape.circle,
      ),
      child: Text(number, style: style),
    ),
  );
}

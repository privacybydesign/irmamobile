import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";

/// What a [ValueTag] says about a value: it is exactly what was asked
/// (green, with a check), it is not (red), or it is what is asked of a card
/// that is not in the app yet (blue).
enum ValueTagTone { match, mismatch, asked }

/// A tag next to a value: "Exactly what they ask", "Asked: {value}",
/// "Asked". 24 high, round.
class ValueTag extends StatelessWidget {
  final String text;
  final ValueTagTone tone;

  const ValueTag({super.key, required this.text, required this.tone});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final (fill, ink) = switch (tone) {
      ValueTagTone.match => (palette.successSurface, palette.successText),
      ValueTagTone.mismatch => (palette.errorSurface, palette.errorText),
      ValueTagTone.asked => (palette.infoSurface, palette.link),
    };
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: ShapeDecoration(color: fill, shape: const StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 3,
        children: [
          if (tone == ValueTagTone.match)
            Icon(Icons.check_rounded, size: 13, color: ink),
          Text(
            text,
            style: palette
                .body(12, weight: FontWeight.w600)
                .copyWith(color: ink, height: 16 / 12),
          ),
        ],
      ),
    );
  }
}

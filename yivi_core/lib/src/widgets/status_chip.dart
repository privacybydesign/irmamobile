import "package:material_ui/material_ui.dart";

import "../theme/yivi_corners.dart";
import "../theme/yivi_palette.dart";
import "../theme/yivi_tone.dart";

/// A short fact as a chip, the one chip of the app: "by Yivi", "3 cards",
/// "Valid until 31-08-2027", "New", "Expired", a count. 28 high and as
/// wide as its one line (a label too long for the room ends in "…"), with
/// an optional [icon] in front.
///
/// [tone] gives the colours: neutral is white with an outline, the others
/// a soft fill with the text in the matching strong colour (info blue, the
/// green of success, the orange of a warning, the red of danger).
class StatusChip extends StatelessWidget {
  static const height = 28.0;

  final String label;
  final YiviTone tone;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    this.tone = YiviTone.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    // Chips differ from the dialog disc in three tones: neutral is white
    // with an outline, info is the light tint, danger has the error text.
    final (fill, ink) = switch (tone) {
      YiviTone.neutral => (palette.surface, palette.heading),
      YiviTone.info => (palette.tint, palette.link),
      YiviTone.danger => (palette.tone(tone).$1, palette.errorText),
      _ => palette.tone(tone),
    };
    final style = palette
        .body(12, weight: FontWeight.w600)
        .copyWith(color: ink);
    final icon = this.icon;
    return Container(
      height: height,
      constraints: const BoxConstraints(minWidth: height),
      padding: EdgeInsetsDirectional.only(
        start: icon == null ? 12 : 8,
        end: 12,
      ),
      decoration: ShapeDecoration(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: YiviCorners.chipRadius,
          side: tone == YiviTone.neutral
              ? BorderSide(color: palette.outline)
              : BorderSide.none,
        ),
      ),
      // As wide as the label, not as the row it is in.
      child: Center(
        widthFactor: 1,
        child: Text.rich(
          TextSpan(
            children: [
              if (icon != null)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 4),
                    child: Icon(icon, size: 14, color: ink),
                  ),
                ),
              TextSpan(text: label),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );
  }
}

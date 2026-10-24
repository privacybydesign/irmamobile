import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";
import "glass/glass_dialog.dart";

/// A short fact as a pill, the one chip of the app: "by Yivi", "3 cards",
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
  final DialogTone tone;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    this.tone = DialogTone.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final (fill, ink) = switch (tone) {
      DialogTone.neutral => (palette.surface, palette.heading),
      DialogTone.info => (palette.tint, palette.link),
      DialogTone.success => (palette.successSurface, palette.successText),
      DialogTone.warning => (palette.warningSurface, palette.warningText),
      DialogTone.danger => (palette.errorSurface, palette.errorText),
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
        shape: StadiumBorder(
          side: tone == DialogTone.neutral
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

/// [StatusChip]s in a row that wraps.
class StatusChipRow extends StatelessWidget {
  final List<Widget> chips;

  const StatusChipRow({super.key, required this.chips});

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 8, runSpacing: 8, children: chips);
}

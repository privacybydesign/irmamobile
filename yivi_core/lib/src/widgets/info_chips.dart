import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";

/// A short fact as a pill, e.g. "by Yivi" or "Valid until 31-08-2027".
/// [tinted] gives the blue pill that says what something is for ("For
/// Webshop Noord · step 1 of 2").
class InfoChip extends StatelessWidget {
  final String label;
  final bool tinted;

  const InfoChip({super.key, required this.label, this.tinted = false});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: ShapeDecoration(
        color: tinted ? palette.tint : palette.surface,
        shape: StadiumBorder(side: BorderSide(color: palette.outline)),
      ),
      // As wide as the label, not as the row it is in.
      child: Center(
        widthFactor: 1,
        // One line: a name too long for the room ends in "…".
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: palette
              .body(12, weight: FontWeight.w600)
              .copyWith(color: tinted ? palette.link : palette.heading),
        ),
      ),
    );
  }
}

/// [InfoChip]s in a row that wraps.
class InfoChipRow extends StatelessWidget {
  final List<InfoChip> chips;

  const InfoChipRow({super.key, required this.chips});

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 8, runSpacing: 8, children: chips);
}

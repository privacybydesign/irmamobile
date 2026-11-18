import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";

/// The header above a group of rows or cards: the palette's section header,
/// 24 above it and [below] under it, [inset] in from the group's side. A
/// [hint] (grey, small) can stand at its end, such as "Pick several".
class SectionHeader extends StatelessWidget {
  final String text;
  final String? hint;
  final double inset;
  final double below;

  const SectionHeader(
    this.text, {
    super.key,
    this.hint,
    this.inset = YiviSpace.x4,
    this.below = YiviSpace.x8,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final title = Semantics(
      header: true,
      child: Text(text, style: palette.sectionHeader),
    );
    final hint = this.hint;
    return Padding(
      padding: EdgeInsets.fromLTRB(inset, YiviSpace.x24, inset, below),
      child: hint == null
          ? title
          : Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: title),
                Text(
                  hint,
                  style: palette.rowSubtitle.copyWith(
                    color: palette.secondaryText,
                  ),
                ),
              ],
            ),
    );
  }
}

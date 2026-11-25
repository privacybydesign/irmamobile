import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/adaptive_layout.dart";
import "../../../widgets/surfaces/icon_square.dart";
import "../../../widgets/text/translated_text.dart";

/// A row of an enrollment page's group: an icon square, a bold line and a
/// line under it. The welcome page's values and the terms in short.
class EnrollmentPointRow extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final String textKey;

  const EnrollmentPointRow({
    super.key,
    required this.icon,
    required this.titleKey,
    required this.textKey,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final tablet = isTabletWindow(context);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: YiviSpace.x16,
          vertical: YiviSpace.x12,
        ),
        child: Row(
          spacing: YiviSpace.x12,
          children: [
            ExcludeSemantics(
              child: IconSquare(
                icon: icon,
                fill: palette.tint,
                ink: palette.link,
                size: 40,
                iconSize: 22,
                radius: 10,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    titleKey,
                    style: palette
                        .body(tablet ? 16 : 15, weight: FontWeight.w700)
                        .copyWith(color: palette.heading),
                  ),
                  TranslatedText(
                    textKey,
                    style: palette
                        .body(tablet ? 14.5 : 13.5)
                        .copyWith(color: palette.secondaryText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

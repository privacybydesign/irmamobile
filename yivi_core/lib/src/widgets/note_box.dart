import "package:material_ui/material_ui.dart";

import "../theme/yivi_corners.dart";
import "../theme/yivi_palette.dart";

/// An explanation in a rounded box, in the info colour.
class NoteBox extends StatelessWidget {
  final String text;

  const NoteBox({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: ShapeDecoration(
        color: palette.infoSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: YiviCorners.cardRadius,
        ),
      ),
      child: Text(
        text,
        style: palette
            .body(14)
            .copyWith(height: 20 / 14, color: palette.noteText),
      ),
    );
  }
}

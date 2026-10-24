import "package:material_ui/material_ui.dart";

import "../theme/yivi_corners.dart";
import "../theme/yivi_palette.dart";

/// An explanation in a rounded box: in the info colour, or with [warning]
/// in the error colour and a heavier weight.
class NoteBox extends StatelessWidget {
  final String text;
  final bool warning;

  const NoteBox({super.key, required this.text, this.warning = false});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: ShapeDecoration(
        color: warning ? palette.errorSurface : palette.infoSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: YiviCorners.cardRadius,
        ),
      ),
      child: Text(
        text,
        style: palette
            .body(14, weight: warning ? FontWeight.w600 : FontWeight.w400)
            .copyWith(
              height: 20 / 14,
              color: warning ? palette.errorText : palette.noteText,
            ),
      ),
    );
  }
}

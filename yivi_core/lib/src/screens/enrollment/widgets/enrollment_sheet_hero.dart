import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_edges.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/adaptive_layout.dart";
import "../../../widgets/surfaces/icon_square.dart";

/// The picture at the top of a sheet opened from an enrollment step: the
/// steps' icon tile, with the icon of the row or page that opened it.
class EnrollmentSheetHero extends StatelessWidget {
  final IconData icon;

  const EnrollmentSheetHero({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final tablet = isTabletWindow(context);
    return Padding(
      padding: const EdgeInsets.only(top: YiviSpace.x8, bottom: YiviSpace.x24),
      child: Center(
        child: ExcludeSemantics(
          child: IconSquare(
            key: const Key("enrollment_sheet_hero"),
            icon: icon,
            fill: palette.surface,
            ink: palette.link,
            size: tablet ? 132 : 112,
            iconSize: tablet ? 68 : 58,
            radius: YiviCorners.iconTile,
            side: YiviEdges.block(context),
          ),
        ),
      ),
    );
  }
}

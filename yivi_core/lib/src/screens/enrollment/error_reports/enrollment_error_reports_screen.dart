import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_edges.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../widgets/surfaces/icon_square.dart";
import "../../../widgets/surfaces/inset_group.dart";
import "../widgets/enrollment_actions.dart";
import "../widgets/enrollment_page.dart";
import "../widgets/enrollment_point_row.dart";

/// Step 2, "Help improve Yivi?": whether the app may send error reports and
/// now and then its status, in the layout of the Face ID step, with what is
/// sent in short on the page itself. Don't share and Share reports are equal
/// answers ([actions]); either can be changed later in Settings.
class EnrollmentErrorReportsScreen extends StatelessWidget {
  final EnrollmentStepActions actions;

  const EnrollmentErrorReportsScreen({super.key, required this.actions});

  static const _points = [
    (
      Icons.error_outline_rounded,
      "enrollment.error_reports.details.point_1_title",
      "enrollment.error_reports.details.point_1_text",
    ),
    (
      Icons.monitor_heart_outlined,
      "enrollment.error_reports.details.point_2_title",
      "enrollment.error_reports.details.point_2_text",
    ),
    (
      Icons.visibility_off_outlined,
      "enrollment.error_reports.details.point_3_title",
      "enrollment.error_reports.details.point_3_text",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final tablet = isTabletWindow(context);
    final sideways = enrollmentSideways(context);
    final align = sideways ? TextAlign.start : TextAlign.center;
    final tile = tablet ? 168.0 : 132.0;

    final icon = Center(
      child: ExcludeSemantics(
        child: IconSquare(
          icon: Icons.bug_report_outlined,
          fill: palette.surface,
          ink: palette.link,
          size: tile,
          iconSize: tablet ? 88 : 68,
          radius: YiviCorners.iconTile,
          side: YiviEdges.block(context),
        ),
      ),
    );

    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: sideways
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        EnrollmentTitle("enrollment.error_reports.title", textAlign: align),
        const SizedBox(height: YiviSpace.x16),
        // What is sent, in short: what the reporting details sheet held.
        InsetGroup(
          key: const Key("error_reports_points"),
          dividerIndent: 68,
          children: [
            for (final (icon, title, text) in _points)
              EnrollmentPointRow(icon: icon, titleKey: title, textKey: text),
          ],
        ),
        const SizedBox(height: YiviSpace.x12),
        Text(
          context.tr("enrollment.error_reports.later"),
          textAlign: align,
          style: palette.body(14).copyWith(color: palette.secondaryText),
        ),
      ],
    );
    final buttons = SizedBox(
      width: double.infinity,
      child: EnrollmentStepButtons(actions: actions),
    );

    // Upright the icon and the text together in the middle, the buttons
    // low; sideways the text with the buttons beside the icon.
    if (!sideways) {
      return EnrollmentPage(
        about: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: YiviSpace.x24),
            text,
          ],
        ),
        action: buttons,
      );
    }
    final action = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        text,
        const SizedBox(height: YiviSpace.x16),
        buttons,
      ],
    );
    return EnrollmentPage(about: icon, action: action);
  }
}

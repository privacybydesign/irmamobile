import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_edges.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../widgets/buttons/link.dart";
import "../../../widgets/sheet/sheet.dart";
import "../../../widgets/surfaces/icon_square.dart";
import "../welcome/widgets/error_reporting_info_bottom_sheet.dart";
import "../widgets/enrollment_actions.dart";
import "../widgets/enrollment_page.dart";

/// Step 2, "Help improve Yivi?": whether the app may send error reports and
/// now and then its status, in the layout of the Face ID step. Don't share
/// and Share reports are equal answers ([actions]); either can be changed
/// later in Settings.
class EnrollmentErrorReportsScreen extends StatelessWidget {
  final EnrollmentStepActions actions;

  const EnrollmentErrorReportsScreen({super.key, required this.actions});

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
        const SizedBox(height: YiviSpace.x8),
        EnrollmentLead("enrollment.error_reports.body", textAlign: align),
        const SizedBox(height: YiviSpace.x8),
        Text(
          context.tr("enrollment.error_reports.later"),
          textAlign: align,
          style: palette.body(14).copyWith(color: palette.secondaryText),
        ),
        Link(
          label: context.tr("enrollment.error_reports.what"),
          onTap: () => showTitledSheet(
            context: context,
            titleKey: "enrollment.error_reporting.dialog.title",
            child: const ErrorReportingInfoBottomSheet(),
          ),
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

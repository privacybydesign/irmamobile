import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_space.dart";
import "../../../util/i18n.dart";
import "../../../widgets/sheet/sheet.dart";
import "../../../widgets/surfaces/inset_group.dart";
import "../../../widgets/text/section_header.dart";
import "../widgets/enrollment_point_row.dart";
import "../widgets/enrollment_sheet_hero.dart";

/// "What is sent?" from Help improve Yivi?: what error reports send, in
/// short, in the build of the terms sheets.
Future<void> showReportingDetailsSheet(BuildContext context) => showSheet<void>(
  context: context,
  builder: (context) => const _ReportingDetailsSheet(),
);

class _ReportingDetailsSheet extends StatelessWidget {
  const _ReportingDetailsSheet();

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
    return SheetPage.scroll(
      key: const Key("reporting_details_sheet"),
      title: SheetTitle(context.tr("enrollment.error_reports.details.title")),
      padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EnrollmentSheetHero(icon: Icons.bug_report_outlined),
          SectionHeader(context.tr("enrollment.terms.in_short")),
          InsetGroup(
            dividerIndent: 68,
            children: [
              for (final (icon, title, text) in _points)
                EnrollmentPointRow(icon: icon, titleKey: title, textKey: text),
            ],
          ),
          const SizedBox(height: YiviSpace.x24),
        ],
      ),
    );
  }
}

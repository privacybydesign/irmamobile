import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../providers/irma_repository_provider.dart";
import "../../../providers/preferences_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../widgets/buttons/pill_buttons.dart";
import "../../../widgets/surfaces/inset_group.dart";
import "../../../widgets/text/translated_text.dart";
import "../welcome/widgets/error_report_switch.dart";
import "../welcome/widgets/terms_check_box.dart";
import "../widgets/enrollment_check_card.dart";
import "../widgets/enrollment_page.dart";
import "../widgets/enrollment_point_row.dart";

/// Step 1, "Before you start": the terms in three points with a link to the
/// full terms, whether to share error reports, and the terms to accept
/// before Continue.
class EnrollmentTermsScreen extends ConsumerWidget {
  final bool isAccepted;
  final ValueChanged<bool> onToggleAccepted;
  final VoidCallback onContinue;

  const EnrollmentTermsScreen({
    super.key,
    required this.isAccepted,
    required this.onToggleAccepted,
    required this.onContinue,
  });

  static const _points = [
    (
      Icons.shield_outlined,
      "enrollment.terms.point_1_title",
      "enrollment.terms.point_1_text",
    ),
    (
      Icons.visibility_off_outlined,
      "enrollment.terms.point_2_title",
      "enrollment.terms.point_2_text",
    ),
    (
      Icons.smartphone_rounded,
      "enrollment.terms.point_3_title",
      "enrollment.terms.point_3_text",
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final tablet = isTabletWindow(context);
    final sideways = enrollmentSideways(context);
    final preferences = ref.watch(preferencesProvider);
    final termsUrl = context.lang == "nl"
        ? preferences.mostRecentTermsUrlNl
        : preferences.mostRecentTermsUrlEn;

    final about = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnrollmentTitle(
          "enrollment.terms.title",
          textAlign: sideways ? TextAlign.start : TextAlign.center,
        ),
        InsetGroup(
          header: context.tr("enrollment.terms.terms_header"),
          dividerIndent: 68,
          children: [
            for (final (icon, title, text) in _points)
              EnrollmentPointRow(icon: icon, titleKey: title, textKey: text),
            _ReadTermsRow(onTap: () => browserOf(context).openLink(termsUrl)),
          ],
        ),
        InsetGroup(
          header: context.tr("enrollment.terms.improve_header"),
          children: const [ErrorReportSwitch()],
        ),
      ],
    );

    final action = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnrollmentCheckCard(
          child: TermsCheckBox(
            isAccepted: isAccepted,
            onToggleAccepted: onToggleAccepted,
          ),
        ),
        const SizedBox(height: YiviSpace.x8),
        // Before any data is processed: where to read what happens with it.
        TranslatedText(
          "enrollment.terms_and_conditions.privacy_policy_markdown",
          key: const Key("enrollment_privacy_policy_link"),
          translationParams: {
            "privacy_url": context.tr("more_tab.privacy_policy_link"),
          },
          style: palette.caption.copyWith(color: palette.secondaryText),
        ),
        const SizedBox(height: YiviSpace.x12),
        PrimaryPillButton(
          key: const Key("enrollment_terms_continue"),
          label: context.tr("enrollment.terms.continue"),
          size: tablet ? PillSize.large : PillSize.regular,
          onPressed: isAccepted ? onContinue : null,
        ),
      ],
    );

    return EnrollmentPage(about: about, action: action, aboutAtTop: true);
  }
}

/// The last row of the terms in short: the full terms, on the website.
class _ReadTermsRow extends StatelessWidget {
  final VoidCallback onTap;

  const _ReadTermsRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final label = context.tr("enrollment.terms.read_full");
    return Semantics(
      link: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        key: const Key("enrollment_terms_read_full"),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: YiviSpace.x16,
            vertical: YiviSpace.x12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: palette
                      .body(15, weight: FontWeight.w600)
                      .copyWith(color: palette.link),
                ),
              ),
              Icon(Icons.open_in_new_rounded, size: 18, color: palette.link),
            ],
          ),
        ),
      ),
    );
  }
}

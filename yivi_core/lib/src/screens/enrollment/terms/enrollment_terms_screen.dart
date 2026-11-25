import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../providers/irma_repository_provider.dart";
import "../../../providers/preferences_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/i18n.dart";
import "../../../widgets/sheet/sheet.dart";
import "../../../widgets/surfaces/icon_square.dart";
import "../../../widgets/surfaces/inset_group.dart";
import "../../../widgets/surfaces/list_row.dart";
import "../../../widgets/text/section_header.dart";
import "../widgets/enrollment_actions.dart";
import "../widgets/enrollment_page.dart";
import "../widgets/enrollment_point_row.dart";
import "../widgets/enrollment_sheet_hero.dart";

/// Step 1, "Before you start": the terms of use and the privacy policy, each
/// a row that opens it in a sheet (in short, and the full text online), and
/// Accept and continue, which accepts the terms. The privacy policy is only
/// there to read.
class EnrollmentTermsScreen extends ConsumerWidget {
  final EnrollmentStepActions actions;

  const EnrollmentTermsScreen({super.key, required this.actions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final sideways = enrollmentSideways(context);
    final align = sideways ? TextAlign.start : TextAlign.center;

    final about = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: sideways
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        ExcludeSemantics(
          child: IconSquare(
            icon: Icons.description_outlined,
            fill: palette.surface,
            ink: palette.link,
            size: 72,
            iconSize: 38,
            radius: 18,
          ),
        ),
        const SizedBox(height: YiviSpace.x16),
        EnrollmentTitle("enrollment.terms.title", textAlign: align),
        const SizedBox(height: YiviSpace.x8),
        EnrollmentLead("enrollment.terms.lead", textAlign: align),
        const SizedBox(height: YiviSpace.x24),
        InsetGroup(
          dividerIndent: 68,
          children: [
            _DocumentRow(
              key: const Key("enrollment_terms_open"),
              icon: Icons.description_outlined,
              titleKey: "enrollment.terms.terms_row_title",
              textKey: "enrollment.terms.terms_row_text",
              onTap: () => showLegalSheet(context, LegalDocument.terms),
            ),
            _DocumentRow(
              key: const Key("enrollment_privacy_open"),
              icon: Icons.verified_user_outlined,
              titleKey: "enrollment.terms.privacy_row_title",
              textKey: "enrollment.terms.privacy_row_text",
              onTap: () => showLegalSheet(context, LegalDocument.privacy),
            ),
          ],
        ),
      ],
    );

    final action = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr("enrollment.terms.agree"),
          key: const Key("enrollment_terms_agree"),
          textAlign: TextAlign.center,
          style: palette
              .body(13)
              .copyWith(color: palette.secondaryText, height: 19 / 13),
        ),
        const SizedBox(height: YiviSpace.x12),
        EnrollmentStepButtons(actions: actions),
      ],
    );

    return EnrollmentPage(about: about, action: action);
  }
}

/// A document to open: its icon, its name and what it is about.
class _DocumentRow extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final String textKey;
  final VoidCallback onTap;

  const _DocumentRow({
    super.key,
    required this.icon,
    required this.titleKey,
    required this.textKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return ListRow(
      leading: IconSquare(
        icon: icon,
        fill: palette.tint,
        ink: palette.link,
        size: 40,
        iconSize: 22,
        radius: 10,
      ),
      title: context.tr(titleKey),
      subtitle: context.tr(textKey),
      subtitleMaxLines: 2,
      onTap: onTap,
    );
  }
}

/// The terms of use and the privacy policy.
enum LegalDocument { terms, privacy }

/// [document] in the app's sheet: in short at the top, then a way to the
/// full text, online on yivi.app (the version that is accepted).
Future<void> showLegalSheet(BuildContext context, LegalDocument document) =>
    showSheet<void>(
      context: context,
      builder: (context) => _LegalSheet(document: document),
    );

class _LegalSheet extends ConsumerWidget {
  final LegalDocument document;

  const _LegalSheet({required this.document});

  static const _termsPoints = [
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

  static const _privacyPoints = [
    (
      Icons.smartphone_rounded,
      "enrollment.terms.privacy_point_1_title",
      "enrollment.terms.privacy_point_1_text",
    ),
    (
      Icons.dns_outlined,
      "enrollment.terms.privacy_point_2_title",
      "enrollment.terms.privacy_point_2_text",
    ),
    (
      Icons.person_outline_rounded,
      "enrollment.terms.privacy_point_3_title",
      "enrollment.terms.privacy_point_3_text",
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final terms = document == LegalDocument.terms;
    final preferences = ref.watch(preferencesProvider);
    // The terms in the version the user accepts, as everywhere in the app;
    // the privacy policy where the More tab links to it.
    final url = terms
        ? (context.lang == "nl"
              ? preferences.mostRecentTermsUrlNl
              : preferences.mostRecentTermsUrlEn)
        : context.tr("more_tab.privacy_policy_link");
    final points = terms ? _termsPoints : _privacyPoints;
    return SheetPage.scroll(
      key: Key(terms ? "legal_sheet_terms" : "legal_sheet_privacy"),
      title: SheetTitle(
        context.tr(
          terms
              ? "enrollment.terms.terms_row_title"
              : "enrollment.terms.privacy_row_title",
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EnrollmentSheetHero(
            icon: terms
                ? Icons.description_outlined
                : Icons.verified_user_outlined,
          ),
          SectionHeader(context.tr("enrollment.terms.in_short")),
          InsetGroup(
            dividerIndent: 68,
            children: [
              for (final (icon, title, text) in points)
                EnrollmentPointRow(icon: icon, titleKey: title, textKey: text),
            ],
          ),
          const SizedBox(height: YiviSpace.x16),
          InsetGroup(
            children: [
              ListRow(
                key: const Key("legal_sheet_read_full"),
                title: context.tr(
                  terms
                      ? "enrollment.terms.read_terms"
                      : "enrollment.terms.read_privacy",
                ),
                link: true,
                trailingWidget: Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: palette.link,
                ),
                onTap: () => browserOf(context).openLink(url),
              ),
            ],
          ),
          const SizedBox(height: YiviSpace.x24),
        ],
      ),
    );
  }
}

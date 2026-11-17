import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../widgets/glass/glass_group.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/icon_square.dart";
import "../../../widgets/surface_card.dart";
import "../../../widgets/translated_text.dart";
import "../widgets/enrollment_page.dart";
import "welcome_card_fan.dart";
import "widgets/error_report_switch.dart";
import "widgets/terms_check_box.dart";

/// The first page of the enrollment: what Yivi is, whether to share error
/// reports, and the terms, which must be accepted before Get started.
class WelcomeScreen extends StatelessWidget {
  final bool isAccepted;
  final ValueChanged<bool> onToggleAccepted;
  final VoidCallback onContinue;

  const WelcomeScreen({
    super.key,
    required this.isAccepted,
    required this.onToggleAccepted,
    required this.onContinue,
  });

  static const _values = [
    (
      Icons.person_rounded,
      "enrollment.welcome.value_1_title",
      "enrollment.welcome.value_1_text",
    ),
    (
      Icons.check_rounded,
      "enrollment.welcome.value_2_title",
      "enrollment.welcome.value_2_text",
    ),
    (
      Icons.lock_rounded,
      "enrollment.welcome.value_3_title",
      "enrollment.welcome.value_3_text",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tablet = isTabletWindow(context);
    final sideways = enrollmentSideways(context);
    // A phone held sideways: the values scroll, the terms and the button
    // stay at the bottom of the column.
    final scrollValues = sideways && !tablet;

    final cardWidth = tablet ? 300.0 : (sideways ? 180.0 : 240.0);
    final about = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: WelcomeCardFan(width: cardWidth),
        ),
        const SizedBox(height: YiviSpace.x16),
        const EnrollmentTitle(
          "enrollment.welcome.title",
          textAlign: TextAlign.center,
        ),
      ],
    );

    final values = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassGroup(
          dividerIndent: 68,
          children: [
            for (final (icon, title, text) in _values)
              _ValueRow(icon: icon, titleKey: title, textKey: text),
          ],
        ),
        const SizedBox(height: YiviSpace.x8),
        const ErrorReportSwitch(),
      ],
    );

    final bottom = [
      _CheckCard(
        child: TermsCheckBox(
          isAccepted: isAccepted,
          onToggleAccepted: onToggleAccepted,
        ),
      ),
      const SizedBox(height: YiviSpace.x12),
      FancyPillButton(
        key: const Key("enrollment_next_button"),
        label: context.tr("enrollment.welcome.start"),
        size: tablet ? PillSize.large : PillSize.regular,
        onPressed: isAccepted ? onContinue : null,
      ),
    ];

    final action = scrollValues
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    top: YiviSpace.x16,
                    bottom: YiviSpace.x12,
                  ),
                  child: values,
                ),
              ),
              ...bottom,
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              values,
              const SizedBox(height: YiviSpace.x16),
              ...bottom,
            ],
          );

    return EnrollmentPage(about: about, action: action, fillAction: true);
  }
}

class _ValueRow extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final String textKey;

  const _ValueRow({
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

/// A checkbox row on its own rounded surface.
class _CheckCard extends StatelessWidget {
  final Widget child;

  const _CheckCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(
        YiviSpace.x4,
        YiviSpace.x4,
        YiviSpace.x16,
        YiviSpace.x4,
      ),
      child: child,
    );
  }
}

import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_shadows.dart";
import "../../../widgets/glass/glass_group.dart";
import "../../../widgets/glass/pill_buttons.dart";
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
    final tablet = enrollmentTablet(context);
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
        const SizedBox(height: 16),
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
        const SizedBox(height: 8),
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
      const SizedBox(height: 12),
      FancyPillButton(
        key: const Key("enrollment_next_button"),
        label: FlutterI18n.translate(context, "enrollment.welcome.start"),
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
                  padding: const EdgeInsets.only(top: 16, bottom: 12),
                  child: values,
                ),
              ),
              ...bottom,
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [values, const SizedBox(height: 16), ...bottom],
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
    final tablet = enrollmentTablet(context);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          spacing: 12,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.tint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: palette.link),
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
    final palette = YiviPalette.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: palette.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: YiviCorners.cardRadius,
        ),
        shadows: [YiviShadows.cardIn(dark: palette.isDark)],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
        child: child,
      ),
    );
  }
}

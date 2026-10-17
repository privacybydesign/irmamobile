import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../widgets/glass/floating_bar_placement.dart";
import "../../../widgets/glass/glass_group.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/translated_text.dart";
import "widgets/error_reporting_check_box.dart";
import "widgets/terms_check_box.dart";

// for first time terms acceptance
class AcceptTermsScreen extends StatelessWidget {
  final bool isAccepted;
  final Function(bool) onToggleAccepted;
  final VoidCallback onContinue;
  final VoidCallback onPrevious;

  const AcceptTermsScreen({
    required this.isAccepted,
    required this.onToggleAccepted,
    required this.onContinue,
    required this.onPrevious,
  });

  static const _values = [
    (Icons.person_rounded, "enrollment.terms_and_conditions.point_1"),
    (Icons.smartphone_rounded, "enrollment.terms_and_conditions.point_2"),
    (Icons.visibility_rounded, "enrollment.terms_and_conditions.point_3"),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: YiviBackButton(onTap: onPrevious),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TranslatedText(
                        "enrollment.terms_and_conditions.title",
                        isHeader: true,
                        style: palette
                            .display(26, weight: FontWeight.w700)
                            .copyWith(height: 36 / 26),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
                      child: TranslatedText(
                        "enrollment.terms_and_conditions.explanation",
                        style: palette.body(16).copyWith(height: 24 / 16),
                      ),
                    ),
                    GlassGroup(
                      dividerIndent: 72,
                      children: [
                        for (final (icon, key) in _values)
                          _ValueRow(icon: icon, translationKey: key),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                FloatingBarPlacement.buttonPadding(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  _CheckCard(
                    child: TermsCheckBox(
                      isAccepted: isAccepted,
                      onToggleAccepted: onToggleAccepted,
                    ),
                  ),
                  _CheckCard(child: ErrorReportingCheckBox()),
                  FancyPillButton(
                    key: const Key("enrollment_next_button"),
                    label: FlutterI18n.translate(context, "ui.next"),
                    onPressed: isAccepted ? onContinue : null,
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

class _ValueRow extends StatelessWidget {
  final IconData icon;
  final String translationKey;

  const _ValueRow({required this.icon, required this.translationKey});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: palette.tint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: palette.link),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TranslatedText(
                translationKey,
                style: palette.body(16).copyWith(height: 24 / 16),
              ),
            ),
          ),
        ],
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
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        shadows: [
          BoxShadow(
            color: palette.isDark
                ? const Color(0x40000000)
                : const Color(0x17000000),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
        child: child,
      ),
    );
  }
}

import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/translated_text.dart";
import "../../../widgets/yivi_progress_indicator.dart";

/// The text and buttons of an introduction step: the step dots, a centred
/// title and explanation, and "Next" with "Previous" under it.
class EnrollmentInstruction extends StatelessWidget {
  final int? stepIndex;
  final int? stepCount;
  final String titleTranslationKey;
  final String explanationTranslationKey;
  final VoidCallback onContinue;
  final VoidCallback? onPrevious;

  const EnrollmentInstruction({
    this.stepIndex,
    this.stepCount,
    required this.titleTranslationKey,
    required this.explanationTranslationKey,
    required this.onContinue,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (stepIndex != null && stepCount != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: YiviProgressIndicator(
                      stepCount: stepCount!,
                      stepIndex: stepIndex!,
                      centered: true,
                    ),
                  ),
                TranslatedText(
                  titleTranslationKey,
                  isHeader: true,
                  textAlign: TextAlign.center,
                  style: palette
                      .display(26, weight: FontWeight.w700)
                      .copyWith(height: 34 / 26),
                ),
                const SizedBox(height: 12),
                TranslatedText(
                  explanationTranslationKey,
                  textAlign: TextAlign.center,
                  style: palette.body(16).copyWith(height: 24 / 16),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4,
            children: [
              FancyPillButton(
                key: const Key("enrollment_next_button"),
                label: FlutterI18n.translate(context, "ui.next"),
                onPressed: onContinue,
              ),
              if (onPrevious != null)
                PillButton(
                  key: const Key("enrollment_previous_button"),
                  label: FlutterI18n.translate(context, "ui.previous"),
                  onPressed: onPrevious,
                  style: PillStyle.text,
                  height: 48,
                )
              else
                // Keeps the layout from jumping between the steps.
                const SizedBox(height: 48),
            ],
          ),
        ),
      ],
    );
  }
}

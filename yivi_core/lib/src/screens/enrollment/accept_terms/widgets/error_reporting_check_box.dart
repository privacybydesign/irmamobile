import "package:flutter/gestures.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../../data/feature_flags.dart";
import "../../../../providers/feature_flag_provider.dart";
import "../../../../providers/irma_repository_provider.dart";
import "../../../../theme/theme.dart";
import "../../../../widgets/yivi_bottom_sheet.dart";
import "error_reporting_info_bottom_sheet.dart";
import "onboarding_checkbox.dart";
import "onboarding_info_sheet.dart";

class ErrorReportingCheckBox extends ConsumerWidget {
  Future<void> _showErrorReportingInfoBottomSheet(BuildContext context) =>
      showYiviBottomSheet(
        context: context,
        titleKey: "enrollment.error_reporting.dialog.title",
        child: ErrorReportingInfoBottomSheet(),
      );

  Future<void> _showOnboardingInfoSheet(BuildContext context) =>
      showOnboardingInfoSheet(
        context: context,
        titleKey: "enrollment.error_reporting.accept.share_errors",
        textKey: "enrollment.onboarding_v2.error_reporting_explanation",
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final repo = IrmaRepositoryProvider.of(context);
    final onboardingV2 =
        ref.watch(featureFlagProvider(FeatureFlag.onboardingV2)).value ?? false;
    final showInfo = onboardingV2
        ? _showOnboardingInfoSheet
        : _showErrorReportingInfoBottomSheet;

    // The visible label is assembled from three spans so the middle one can
    // open the info sheet. Translating each part once and sharing it with the
    // screen reader label below keeps the spoken sentence identical to the
    // written one in every locale.
    final optional = FlutterI18n.translate(
      context,
      "enrollment.error_reporting.accept.optional",
    );
    final shareErrors = FlutterI18n.translate(
      context,
      "enrollment.error_reporting.accept.share_errors",
    );
    final withYivi = FlutterI18n.translate(
      context,
      "enrollment.error_reporting.accept.with_yivi",
    );

    // Onboarding v2 drops the "Optional" prefix.
    final label = onboardingV2
        ? "$shareErrors $withYivi"
        : "$optional: $shareErrors $withYivi";

    return Row(
      crossAxisAlignment: onboardingV2
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // The label lives in a sibling widget, so the checkbox itself has no
        // accessible name — merge one in, so a screen reader announces the
        // label together with the checkbox role and its checked state. The
        // rich text keeps its own semantics, which is what makes the
        // info-sheet link reachable.
        MergeSemantics(
          child: Semantics(
            label: label,
            child: StreamBuilder(
              stream: repo.preferences.getReportErrors(),
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                final value = snapshot.hasData && snapshot.data!;

                void onChanged(bool? isAccepted) {
                  if (isAccepted != null) {
                    repo.preferences.setReportErrors(isAccepted);
                  }
                }

                if (onboardingV2) {
                  return OnboardingCheckbox(
                    checkboxKey: const Key("error_reporting_checkbox"),
                    value: value,
                    onChanged: onChanged,
                  );
                }

                return Checkbox(
                  key: const Key("error_reporting_checkbox"),
                  value: value,
                  onChanged: onChanged,
                  activeColor: theme.themeData.colorScheme.secondary,
                );
              },
            ),
          ),
        ),
        if (!onboardingV2) SizedBox(width: theme.smallSpacing),
        // RenderParagraph gives every span carrying a gesture recognizer its
        // own semantics node, which split this one sentence into three: the
        // "Optional:" prefix, the tappable share-errors span and "with Yivi".
        // Replace those with a single node reading the whole sentence.
        //
        // MergeSemantics would also collapse them into one node, but it joins
        // the fragments with newlines ("Optional: \nShare...\n with Yivi"),
        // which is announced with stray pauses. Supplying the label directly
        // and excluding the span semantics gives the clean sentence, and
        // re-declaring onTap keeps the info sheet reachable — the exclusion
        // drops the recognizer's own action along with its node.
        Flexible(
          child: Semantics(
            container: true,
            label: label,
            onTap: () => showInfo(context),
            excludeSemantics: true,
            child: Text.rich(
              TextSpan(
                children: [
                  if (!onboardingV2)
                    TextSpan(
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      text: "$optional: ",
                    ),
                  TextSpan(
                    style: theme.hyperlinkTextStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => showInfo(context),
                    text: shareErrors,
                  ),
                  TextSpan(
                    style: theme.textTheme.bodyMedium,
                    text: " $withYivi",
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

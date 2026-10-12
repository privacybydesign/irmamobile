import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../data/feature_flags.dart";
import "../../../providers/feature_flag_provider.dart";
import "../../../widgets/action_feedback.dart";
import "calm_success_feedback.dart";

class IssuanceSuccessScreen extends ConsumerWidget {
  final Function(BuildContext) onDismiss;

  const IssuanceSuccessScreen({required this.onDismiss});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calm =
        ref.watch(featureFlagProvider(FeatureFlag.calmSuccess)).value ?? false;

    if (calm) {
      return CalmSuccessFeedback(
        appBarTranslationKey: "issuance.success_feedback.calm.app_bar",
        headingTranslationKey: "issuance.success_feedback.calm.heading",
        textTranslationKey: "issuance.success_feedback.calm.text",
        onDismiss: () => onDismiss(context),
      );
    }

    return ActionFeedback(
      success: true,
      titleTranslationKey: "issuance.success_feedback.header",
      explanationTranslationKey: "issuance.success_feedback.text",
      onDismiss: () => onDismiss(context),
    );
  }
}

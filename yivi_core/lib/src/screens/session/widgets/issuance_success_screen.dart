import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../data/feature_flags.dart";
import "../../../providers/feature_flag_provider.dart";
import "../../../widgets/action_feedback.dart";

class IssuanceSuccessScreen extends ConsumerWidget {
  final Function(BuildContext) onDismiss;

  const IssuanceSuccessScreen({required this.onDismiss});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calm =
        ref.watch(featureFlagProvider(FeatureFlag.calmSuccess)).value ?? false;

    return ActionFeedback(
      success: true,
      titleTranslationKey: calm
          ? "issuance.success_feedback.calm_header"
          : "issuance.success_feedback.header",
      explanationTranslationKey: calm
          ? "issuance.success_feedback.calm_text"
          : "issuance.success_feedback.text",
      onDismiss: () => onDismiss(context),
    );
  }
}

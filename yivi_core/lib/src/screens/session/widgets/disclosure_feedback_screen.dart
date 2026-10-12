import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../data/feature_flags.dart";
import "../../../providers/feature_flag_provider.dart";
import "../../../widgets/action_feedback.dart";
import "calm_success_feedback.dart";

enum DisclosureFeedbackType { success, canceled, notSatisfiable }

class DisclosureFeedbackScreen extends ConsumerStatefulWidget {
  static const _translationKeys = {
    DisclosureFeedbackType.success: "success",
    DisclosureFeedbackType.canceled: "canceled",
    DisclosureFeedbackType.notSatisfiable: "not_satisfiable",
  };

  final DisclosureFeedbackType feedbackType;
  final String otherParty;
  final Function(BuildContext) onDismiss;
  final bool isSignatureSession;

  final String? _translationKey;

  DisclosureFeedbackScreen({
    required this.feedbackType,
    required this.otherParty,
    required this.onDismiss,
    bool? isSignatureSession,
  }) : isSignatureSession = isSignatureSession ?? false,
       _translationKey = _translationKeys[feedbackType];

  @override
  ConsumerState<DisclosureFeedbackScreen> createState() {
    return DisclosureFeedbackScreenState();
  }
}

class DisclosureFeedbackScreenState
    extends ConsumerState<DisclosureFeedbackScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherPartyTranslationParam = {"otherParty": widget.otherParty};
    final calm =
        ref.watch(featureFlagProvider(FeatureFlag.calmSuccess)).value ?? false;

    // "Shared" is wrong for a signature, so signature sessions keep their copy.
    if (calm &&
        widget.feedbackType == DisclosureFeedbackType.success &&
        !widget.isSignatureSession) {
      return CalmSuccessFeedback(
        appBarTranslationKey: "disclosure.feedback.calm_success.app_bar",
        headingTranslationKey: "disclosure.feedback.calm_success.heading",
        headingTranslationParams: otherPartyTranslationParam,
        textTranslationKey: "disclosure.feedback.calm_success.text",
        onDismiss: () => widget.onDismiss(context),
      );
    }

    return ActionFeedback(
      success: widget.feedbackType == DisclosureFeedbackType.success,
      titleTranslationKey:
          "disclosure.feedback.header.${widget._translationKey}",
      titleTranslationParams: otherPartyTranslationParam,
      explanationTranslationKey:
          'disclosure.feedback.text.${widget._translationKey}${widget.isSignatureSession ? '_signature' : ''}',
      explanationTranslationParams: otherPartyTranslationParam,
      onDismiss: () => widget.onDismiss(context),
    );
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // If the app is resumed remove the route with this screen from the stack.
    if (state == AppLifecycleState.resumed) {
      widget.onDismiss(context);
    }
  }
}

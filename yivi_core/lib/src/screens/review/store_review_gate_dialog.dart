import "dart:async";

import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../providers/preferences_provider.dart";
import "../../providers/store_review_provider.dart";
import "../../widgets/glass/glass_dialog.dart";
import "../../widgets/glass/pill_buttons.dart";
import "store_review_feedback_dialog.dart";

/// Sentiment pre-gate shown after enough successful sessions. Happy users are
/// routed to the native in-app review card; unhappy users are routed to a
/// private feedback box instead of the store. Tapping outside / back counts as
/// "not now" (barrierDismissible), which leaves the terminal flag unset so the
/// single re-ask can still happen later. Modelled on the biometric opt-in
/// dialog; deliberately carries no stars or "rate/review/store" wording.
Future<void> showStoreReviewGateDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _StoreReviewGateDialog(),
  );
}

class _StoreReviewGateDialog extends ConsumerStatefulWidget {
  const _StoreReviewGateDialog();

  @override
  ConsumerState<_StoreReviewGateDialog> createState() =>
      _StoreReviewGateDialogState();
}

class _StoreReviewGateDialogState
    extends ConsumerState<_StoreReviewGateDialog> {
  bool _busy = false;

  Future<void> _positive() async {
    setState(() => _busy = true);
    final service = ref.read(storeReviewServiceProvider);
    // Terminal regardless of what the native card decides to show: a happy
    // user is asked at most once.
    await ref.read(preferencesProvider).setReviewDone(true);
    if (service != null) {
      unawaited(service.requestReview());
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _negative() async {
    setState(() => _busy = true);
    // An unhappy user is never routed to the store again, whether or not they
    // end up sending feedback.
    await ref.read(preferencesProvider).setReviewDone(true);
    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pop();
    await showStoreReviewFeedbackDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    String t(String key) => FlutterI18n.translate(context, key);
    return GlassDialog(
      title: t("review.gate.title"),
      message: t("review.gate.body"),
      actions: [
        FancyPillButton(
          key: const Key("review_gate_positive"),
          label: t("review.gate.positive"),
          onPressed: _busy ? null : _positive,
          height: 52,
        ),
        PillButton(
          key: const Key("review_gate_negative"),
          label: t("review.gate.negative"),
          style: PillStyle.text,
          height: 48,
          onPressed: _busy ? null : _negative,
        ),
      ],
    );
  }
}

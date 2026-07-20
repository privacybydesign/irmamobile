import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../providers/preferences_provider.dart";
import "../../providers/store_review_provider.dart";
import "../../theme/theme.dart";
import "../../widgets/irma_dialog.dart";
import "../../widgets/yivi_themed_button.dart";
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
    final theme = IrmaTheme.of(context);
    return IrmaDialog(
      title: FlutterI18n.translate(context, "review.gate.title"),
      content: FlutterI18n.translate(context, "review.gate.body"),
      child: Column(
        children: [
          YiviThemedButton(
            key: const Key("review_gate_positive"),
            label: "review.gate.positive",
            onPressed: _busy ? null : _positive,
          ),
          SizedBox(height: theme.smallSpacing),
          YiviThemedButton(
            key: const Key("review_gate_negative"),
            label: "review.gate.negative",
            style: YiviButtonStyle.outlined,
            onPressed: _busy ? null : _negative,
          ),
        ],
      ),
    );
  }
}

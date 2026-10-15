import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../sentry/sentry.dart";
import "../../theme/yivi_palette.dart";
import "../../widgets/glass/glass_dialog.dart";
import "../../widgets/glass/pill_buttons.dart";
import "../../widgets/pill_text_field.dart";

/// Private feedback box shown to users who tapped "Not really" on the sentiment
/// gate. Their message is sent to Sentry with `userInitiated: true` (so it goes
/// through even when crash reporting is off), and they are never routed to the
/// store. Carries the same "don't include personal data" transparency note as
/// the NFC error dialog.
Future<void> showStoreReviewFeedbackDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _StoreReviewFeedbackDialog(),
  );
}

class _StoreReviewFeedbackDialog extends ConsumerStatefulWidget {
  const _StoreReviewFeedbackDialog();

  @override
  ConsumerState<_StoreReviewFeedbackDialog> createState() =>
      _StoreReviewFeedbackDialogState();
}

class _StoreReviewFeedbackDialogState
    extends ConsumerState<_StoreReviewFeedbackDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      reportFeedback(text, userInitiated: true);
    }
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    String t(String key) => FlutterI18n.translate(context, key);

    if (_sent) {
      return GlassDialog(
        title: t("review.feedback.title"),
        message: t("review.feedback.thanks"),
        actions: [
          FancyPillButton(
            key: const Key("review_feedback_done"),
            label: t("review.feedback.close"),
            onPressed: () => Navigator.of(context).pop(),
            height: 52,
          ),
        ],
      );
    }

    return GlassDialog(
      title: t("review.feedback.title"),
      message: t("review.feedback.body"),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PillTextField(
            fieldKey: const Key("review_feedback_input"),
            controller: _controller,
            hint: t("review.feedback.hint"),
            minLines: 3,
            maxLines: 6,
            autofocus: true,
            keyboardType: TextInputType.multiline,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              t("review.feedback.privacy"),
              style: palette
                  .body(13)
                  .copyWith(height: 18 / 13, color: palette.secondaryText),
            ),
          ),
        ],
      ),
      actions: [
        FancyPillButton(
          key: const Key("review_feedback_send"),
          label: t("review.feedback.send"),
          onPressed: _send,
          height: 52,
        ),
        PillButton(
          key: const Key("review_feedback_cancel"),
          label: t("review.feedback.cancel"),
          style: PillStyle.text,
          height: 48,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

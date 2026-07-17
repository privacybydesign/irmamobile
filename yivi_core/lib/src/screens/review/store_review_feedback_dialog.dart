import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../sentry/sentry.dart";
import "../../theme/theme.dart";
import "../../widgets/irma_dialog.dart";
import "../../widgets/translated_text.dart";
import "../../widgets/yivi_themed_button.dart";

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
    final theme = IrmaTheme.of(context);

    if (_sent) {
      return IrmaDialog(
        title: FlutterI18n.translate(context, "review.feedback.title"),
        content: FlutterI18n.translate(context, "review.feedback.thanks"),
        child: YiviThemedButton(
          key: const Key("review_feedback_done"),
          label: "review.feedback.close",
          onPressed: () => Navigator.of(context).pop(),
        ),
      );
    }

    final hint = FlutterI18n.translate(context, "review.feedback.hint");

    // Body lives in the child (not IrmaDialog's centered `content`) so it can be
    // left-aligned like a normal form prompt.
    return IrmaDialog(
      title: FlutterI18n.translate(context, "review.feedback.title"),
      content: "",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TranslatedText(
            "review.feedback.body",
            style: theme.textTheme.bodyMedium,
          ),
          SizedBox(height: theme.defaultSpacing),
          // The hint disappears once text is entered, so give screen readers a
          // persistent label for the field's purpose.
          Semantics(
            label: hint,
            textField: true,
            child: TextField(
              key: const Key("review_feedback_input"),
              controller: _controller,
              minLines: 3,
              maxLines: 6,
              autofocus: true,
              keyboardType: TextInputType.multiline,
              // Matches the app's standard text fields (e.g. MRZ manual entry):
              // the global underline InputDecorationTheme, a bodyMedium style, a
              // secondary-coloured cursor and a 50%-opacity hint.
              cursorColor: theme.themeData.colorScheme.secondary,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hint: Text(
                  hint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: theme.defaultSpacing),
          TranslatedText(
            "review.feedback.privacy",
            style: theme.textTheme.bodySmall,
          ),
          SizedBox(height: theme.defaultSpacing),
          YiviThemedButton(
            key: const Key("review_feedback_send"),
            label: "review.feedback.send",
            onPressed: _send,
          ),
          SizedBox(height: theme.smallSpacing),
          YiviThemedButton(
            key: const Key("review_feedback_cancel"),
            label: "review.feedback.cancel",
            style: YiviButtonStyle.outlined,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

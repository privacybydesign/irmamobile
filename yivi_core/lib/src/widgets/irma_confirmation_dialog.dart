import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "glass/pill_buttons.dart";
import "irma_dialog.dart";

class IrmaConfirmationDialog extends StatelessWidget {
  final String titleTranslationKey;
  final String contentTranslationKey;
  final Map<String, String>? contentTranslationParams;
  final String? cancelTranslationKey;
  final Function()? onCancelPressed;
  final String? confirmTranslationKey;
  final Function()? onConfirmPressed;

  /// Makes cancelling the primary action, for confirmations of something the
  /// user probably did not mean to do.
  final bool nudgeCancel;

  /// Confirming deletes or resets something: the confirm button turns red.
  final bool destructive;

  /// Shown above the title, usually a ToneDisc.
  final Widget? icon;

  const IrmaConfirmationDialog({
    required this.titleTranslationKey,
    required this.contentTranslationKey,
    this.contentTranslationParams,
    this.cancelTranslationKey,
    this.onCancelPressed,
    this.confirmTranslationKey,
    this.onConfirmPressed,
    this.nudgeCancel = false,
    this.destructive = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    String t(String key) => FlutterI18n.translate(context, key);

    final onConfirm = onConfirmPressed ?? () => Navigator.of(context).pop(true);
    final onCancel = onCancelPressed ?? () => Navigator.of(context).pop(false);
    final confirmLabel = t(confirmTranslationKey ?? "ui.confirm");
    final cancelLabel = t(cancelTranslationKey ?? "ui.cancel");

    final Widget confirmButton = nudgeCancel
        ? PillButton(
            key: const Key("dialog_confirm_button"),
            label: confirmLabel,
            onPressed: onConfirm,
            style: destructive ? PillStyle.danger : PillStyle.text,
            size: PillSize.regular,
          )
        : destructive
        ? PillButton(
            key: const Key("dialog_confirm_button"),
            label: confirmLabel,
            onPressed: onConfirm,
            style: PillStyle.dangerFilled,
          )
        : FancyPillButton(
            key: const Key("dialog_confirm_button"),
            label: confirmLabel,
            onPressed: onConfirm,
            size: PillSize.regular,
          );

    final Widget cancelButton = nudgeCancel
        ? FancyPillButton(
            key: const Key("dialog_cancel_button"),
            label: cancelLabel,
            onPressed: onCancel,
            size: PillSize.regular,
          )
        : PillButton(
            key: const Key("dialog_cancel_button"),
            label: cancelLabel,
            onPressed: onCancel,
            style: PillStyle.text,
            size: PillSize.regular,
          );

    // Built on IrmaDialog, so tests and callers that look for an IrmaDialog
    // keep finding it.
    return IrmaDialog(
      icon: icon,
      title: t(titleTranslationKey),
      content: FlutterI18n.translate(
        context,
        contentTranslationKey,
        translationParams: contentTranslationParams,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 4,
        children: nudgeCancel
            ? [cancelButton, confirmButton]
            : [confirmButton, cancelButton],
      ),
    );
  }
}

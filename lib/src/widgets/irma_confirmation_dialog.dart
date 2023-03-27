import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../theme/theme.dart';
import 'irma_dialog.dart';
import 'yivi_themed_button.dart';

class IrmaConfirmationDialog extends StatelessWidget {
  final String titleTranslationKey;
  final String contentTranslationKey;
  final Map<String, String>? contentTranslationParams;
  final String? cancelTranslationKey;
  final Function()? onCancelPressed;
  final String? confirmTranslationKey;
  final Function()? onConfirmPressed;
  final bool nudgeCancel;

  const IrmaConfirmationDialog({
    required this.titleTranslationKey,
    required this.contentTranslationKey,
    this.contentTranslationParams,
    this.cancelTranslationKey,
    this.onCancelPressed,
    this.confirmTranslationKey,
    this.onConfirmPressed,
    this.nudgeCancel = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final confirmButton = YiviThemedButton(
      key: const Key('dialog_confirm_button'),
      onPressed: onConfirmPressed ?? () => Navigator.of(context).pop(true),
      label: confirmTranslationKey ?? 'ui.confirm',
      style: !nudgeCancel ? YiviButtonStyle.fancy : YiviButtonStyle.outlined,
    );

    final cancelButton = YiviThemedButton(
      key: const Key('dialog_cancel_button'),
      onPressed: onCancelPressed ?? () => Navigator.of(context).pop(false),
      label: cancelTranslationKey ?? 'ui.cancel',
      style: nudgeCancel ? YiviButtonStyle.fancy : YiviButtonStyle.outlined,
    );

    final spacerWidget = SizedBox(
      height: theme.smallSpacing,
    );

    var buttonWidgets = [
      confirmButton,
      spacerWidget,
      cancelButton,
    ];

    if (nudgeCancel) {
      buttonWidgets = buttonWidgets.reversed.toList();
    }

    return IrmaDialog(
      title: FlutterI18n.translate(context, titleTranslationKey),
      content: FlutterI18n.translate(
        context,
        contentTranslationKey,
        translationParams: contentTranslationParams,
      ),
      child: Column(
        children: buttonWidgets,
      ),
    );
  }
}

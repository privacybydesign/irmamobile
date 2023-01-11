import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../theme/theme.dart';
import 'custom_button.dart';
import 'irma_dialog.dart';

class IrmaConfirmationDialog extends StatelessWidget {
  final String titleTranslationKey;
  final String contentTranslationKey;
  final String? cancelTranslationKey;
  final String? confirmTranslationKey;
  final bool nudgeCancel;

  const IrmaConfirmationDialog({
    required this.titleTranslationKey,
    required this.contentTranslationKey,
    this.cancelTranslationKey,
    this.confirmTranslationKey,
    this.nudgeCancel = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final confirmButton = CustomButton(
      key: const Key('dialog_confirm_button'),
      onPressed: () => Navigator.of(context).pop(true),
      label: confirmTranslationKey ?? 'ui.confirm',
      style: !nudgeCancel ? CustomButtonStyle.fancy : CustomButtonStyle.outlined,
    );

    final cancelButton = CustomButton(
      key: const Key('dialog_cancel_button'),
      onPressed: () => Navigator.of(context).pop(false),
      label: cancelTranslationKey ?? 'ui.cancel',
      style: nudgeCancel ? CustomButtonStyle.fancy : CustomButtonStyle.outlined,
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
      ),
      child: Column(
        children: buttonWidgets,
      ),
    );
  }
}

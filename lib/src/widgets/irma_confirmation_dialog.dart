import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'irma_button.dart';
import 'irma_dialog.dart';
import 'irma_themed_button.dart';

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
    final confirmButton = IrmaButton(
      size: IrmaButtonSize.small,
      onPressed: () => Navigator.of(context).pop(true),
      label: confirmTranslationKey ?? 'ui.confirm',
      isSecondary: nudgeCancel,
    );

    final cancelButton = IrmaButton(
      size: IrmaButtonSize.small,
      onPressed: () => Navigator.of(context).pop(false),
      label: cancelTranslationKey ?? 'ui.cancel',
      isSecondary: !nudgeCancel,
    );

    return IrmaDialog(
      title: FlutterI18n.translate(context, titleTranslationKey),
      content: FlutterI18n.translate(
        context,
        contentTranslationKey,
      ),
      child: Column(
        children: nudgeCancel ? [cancelButton, confirmButton] : [confirmButton, cancelButton],
      ),
    );
  }
}

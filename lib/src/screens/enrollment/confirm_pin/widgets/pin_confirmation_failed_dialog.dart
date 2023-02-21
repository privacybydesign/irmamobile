import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../widgets/irma_button.dart';
import '../../../../widgets/irma_dialog.dart';
import '../../../../widgets/irma_themed_button.dart';

class PinConfirmationFailedDialog extends StatelessWidget {
  final VoidCallback onPressed;

  const PinConfirmationFailedDialog({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IrmaDialog(
      title: FlutterI18n.translate(context, 'confirm_pin.error.title'),
      content: FlutterI18n.translate(context, 'confirm_pin.error.body'),
      child: IrmaButton(
        size: IrmaButtonSize.small,
        onPressed: onPressed,
        label: 'confirm_pin.error.action',
      ),
    );
  }
}

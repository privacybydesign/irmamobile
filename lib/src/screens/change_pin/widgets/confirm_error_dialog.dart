import 'package:flutter/material.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';

class ConfirmErrorDialog extends StatelessWidget {
  final void Function() onClose;

  const ConfirmErrorDialog({
    @required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return IrmaDialog(
      title: 'change_pin.choose_pin.error_title',
      content: 'change_pin.choose_pin.error',
      child: IrmaButton(
        size: IrmaButtonSize.small,
        onPressed: onClose,
        label: 'change_pin.choose_pin.error_action',
      ),
    );
  }
}

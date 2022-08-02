import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';

class ConfirmPinResetDialog extends StatelessWidget {
  final VoidCallback ok, cancel;

  const ConfirmPinResetDialog({
    Key? key,
    required this.ok,
    required this.cancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IrmaDialog(
      title: FlutterI18n.translate(context, 'change_pin.dialog.title'),
      content: FlutterI18n.translate(context, 'change_pin.dialog.body'),
      child: Column(
        children: [
          IrmaButton(
            size: IrmaButtonSize.small,
            onPressed: ok,
            label: 'change_pin.dialog.ok',
          ),
          IrmaButton(
            size: IrmaButtonSize.small,
            onPressed: cancel,
            label: 'change_pin.dialog.cancel',
            isSecondary: true,
          ),
        ],
      ),
    );
  }
}

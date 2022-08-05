import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';

class ConfirmErrorDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IrmaDialog(
      title: FlutterI18n.translate(context, 'change_pin.choose_pin.error_title'),
      content: FlutterI18n.translate(context, 'change_pin.choose_pin.error'),
      child: IrmaButton(
        size: IrmaButtonSize.small,
        onPressed: Navigator.of(context).pop,
        label: 'change_pin.choose_pin.error_action',
      ),
    );
  }
}

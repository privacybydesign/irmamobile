import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../widgets/irma_button.dart';
import '../../../../widgets/irma_dialog.dart';
import '../../../../widgets/irma_themed_button.dart';

class PinConfirmationFailedDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IrmaDialog(
      title: FlutterI18n.translate(context, 'enrollment.choose_pin.error_title'),
      content: FlutterI18n.translate(context, 'enrollment.choose_pin.error'),
      child: IrmaButton(
        size: IrmaButtonSize.small,
        onPressed: Navigator.of(context).pop,
        label: 'enrollment.choose_pin.error_action',
      ),
    );
  }
}

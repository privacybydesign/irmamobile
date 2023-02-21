import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../irma_button.dart';
import '../irma_dialog.dart';
import '../irma_themed_button.dart';

class PinWrongAttemptsDialog extends StatelessWidget {
  final void Function() onClose;
  final int attemptsRemaining;

  const PinWrongAttemptsDialog({
    required this.attemptsRemaining,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return IrmaDialog(
      title: FlutterI18n.translate(context, 'pin_common.invalid_title'),
      content: FlutterI18n.plural(context, 'pin_common.invalid_pin.attempts', attemptsRemaining),
      child: IrmaButton(
        size: IrmaButtonSize.small,
        onPressed: onClose,
        label: 'pin_common.invalid_close',
      ),
    );
  }
}

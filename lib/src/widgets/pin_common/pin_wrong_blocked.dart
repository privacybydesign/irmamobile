// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';
import 'package:irmamobile/src/widgets/pin_common/format_blocked_for.dart';

class PinWrongBlockedDialog extends StatelessWidget {
  final void Function() onClose;
  final int blocked;

  const PinWrongBlockedDialog({
    @required this.blocked,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final blockedForStr = formatBlockedFor(context, Duration(seconds: blocked));

    return IrmaDialog(
      title: FlutterI18n.translate(context, 'pin_common.blocked_title'),
      content: FlutterI18n.translate(context, "pin_common.blocked_pin", translationParams: {"blocked": blockedForStr}),
      child: IrmaButton(
        size: IrmaButtonSize.small,
        onPressed: onClose ?? () => Navigator.of(context).pop(),
        label: 'pin_common.blocked_close',
      ),
    );
  }
}

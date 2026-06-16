import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../../widgets/yivi_dialog.dart";
import "../../../../widgets/yivi_themed_button.dart";

class PinConfirmationFailedDialog extends StatelessWidget {
  final VoidCallback onPressed;

  const PinConfirmationFailedDialog({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return YiviDialog.structured(
      title: FlutterI18n.translate(context, "confirm_pin.error.title"),
      content: FlutterI18n.translate(context, "confirm_pin.error.body"),
      child: YiviThemedButton(
        label: "confirm_pin.error.action",
        onPressed: onPressed,
      ),
    );
  }
}

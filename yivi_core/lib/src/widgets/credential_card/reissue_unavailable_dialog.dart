import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../irma_dialog.dart";
import "../yivi_themed_button.dart";

/// Dialog shown when a user tries to reobtain a credential whose issuer
/// endpoint no longer exists in the current scheme configuration.
///
/// Explains that reissuing is not possible instead of sending the user to a
/// bare 404 page.
class ReissueUnavailableDialog extends StatelessWidget {
  const ReissueUnavailableDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return IrmaDialog(
      title: FlutterI18n.translate(context, "credential.unavailable.title"),
      content: FlutterI18n.translate(context, "credential.unavailable.body"),
      child: YiviThemedButton(
        key: const Key("dialog_close_button"),
        onPressed: () => Navigator.of(context).pop(),
        label: "ui.ok",
        style: YiviButtonStyle.fancy,
      ),
    );
  }
}

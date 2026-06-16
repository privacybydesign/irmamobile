import "package:flutter/widgets.dart";

import "../../../../widgets/yivi_dialog.dart";

class SkipEmailConfirmationDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return YiviDialog.confirmation(
      titleTranslationKey: "enrollment.email.provide.confirm_skip_dialog.title",
      contentTranslationKey:
          "enrollment.email.provide.confirm_skip_dialog.explanation",
      confirmTranslationKey: "ui.skip",
      cancelTranslationKey:
          "enrollment.email.provide.confirm_skip_dialog.decline",
      nudgeCancel: true,
    );
  }
}

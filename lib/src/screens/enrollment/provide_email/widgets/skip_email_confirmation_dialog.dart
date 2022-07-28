import 'package:flutter/widgets.dart';

import '../../../../widgets/irma_confirmation_dialog.dart';

class SkipEmailConfirmationDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const IrmaConfirmationDialog(
      titleTranslationKey: 'enrollment.email.provide.confirm_skip_dialog.title',
      contentTranslationKey: 'enrollment.email.provide.confirm_skip_dialog.explanation',
      confirmTranslationKey: 'ui.skip',
      cancelTranslationKey: 'enrollment.email.provide.confirm_skip_dialog.decline',
      nudgeCancel: true,
    );
  }
}

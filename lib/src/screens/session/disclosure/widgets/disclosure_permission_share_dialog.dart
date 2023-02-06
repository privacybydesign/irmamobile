import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../models/session.dart';
import '../../../../widgets/irma_confirmation_dialog.dart';

class DisclosurePermissionConfirmDialog extends StatelessWidget {
  final RequestorInfo requestor;

  const DisclosurePermissionConfirmDialog({
    required this.requestor,
  });

  @override
  Widget build(BuildContext context) {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return IrmaConfirmationDialog(
      titleTranslationKey: 'disclosure_permission.confirm_dialog.title',
      contentTranslationKey: 'disclosure_permission.confirm_dialog.explanation',
      contentTranslationParams: {
        'requestorName': requestor.name.translate(lang),
      },
      confirmTranslationKey: 'disclosure_permission.confirm_dialog.confirm',
      cancelTranslationKey: 'disclosure_permission.confirm_dialog.decline',
    );
  }
}

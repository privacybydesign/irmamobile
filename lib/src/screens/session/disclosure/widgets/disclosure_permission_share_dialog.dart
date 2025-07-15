import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../models/session.dart';
import '../../../../widgets/irma_confirmation_dialog.dart';

class DisclosurePermissionConfirmDialog extends StatelessWidget {
  final RequestorInfo requestor;
  final bool isSignatureSession;

  const DisclosurePermissionConfirmDialog({required this.requestor, this.isSignatureSession = false});

  @override
  Widget build(BuildContext context) {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return IrmaConfirmationDialog(
      titleTranslationKey: 'disclosure_permission.confirm_dialog.${isSignatureSession ? 'title_signature' : 'title'}',
      contentTranslationKey:
          'disclosure_permission.confirm_dialog.${isSignatureSession ? 'explanation_signature' : 'explanation'}',
      contentTranslationParams: {'requestorName': requestor.name.translate(lang)},
      confirmTranslationKey:
          'disclosure_permission.confirm_dialog.${isSignatureSession ? 'confirm_signature' : 'confirm'}',
      cancelTranslationKey:
          'disclosure_permission.confirm_dialog.${isSignatureSession ? 'decline_signature' : 'decline'}',
    );
  }
}

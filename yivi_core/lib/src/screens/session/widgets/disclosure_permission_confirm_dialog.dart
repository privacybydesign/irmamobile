import "package:flutter/material.dart";

import "../../../models/schemaless/schemaless_events.dart";
import "../../../widgets/irma_confirmation_dialog.dart";

class DisclosurePermissionConfirmDialog extends StatelessWidget {
  final TrustedParty requestor;
  final bool isSignatureSession;

  const DisclosurePermissionConfirmDialog({
    required this.requestor,
    this.isSignatureSession = false,
  });

  @override
  Widget build(BuildContext context) {
    return IrmaConfirmationDialog(
      titleTranslationKey:
          'disclosure_permission.confirm_dialog.${isSignatureSession ? 'title_signature' : 'title'}',
      contentTranslationKey:
          'disclosure_permission.confirm_dialog.${isSignatureSession ? 'explanation_signature' : 'explanation'}',
      contentTranslationParams: {"requestorName": requestor.name},
      confirmTranslationKey:
          'disclosure_permission.confirm_dialog.${isSignatureSession ? 'confirm_signature' : 'confirm'}',
      cancelTranslationKey:
          'disclosure_permission.confirm_dialog.${isSignatureSession ? 'decline_signature' : 'decline'}',
    );
  }
}

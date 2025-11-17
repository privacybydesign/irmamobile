import 'package:flutter/material.dart';

import '../../../../widgets/irma_confirmation_dialog.dart';

class ConfirmSchemePublicKeyDialog extends StatelessWidget {
  final String publicKey;

  const ConfirmSchemePublicKeyDialog({required this.publicKey});

  @override
  Widget build(BuildContext context) {
    return IrmaConfirmationDialog(
      titleTranslationKey: 'debug.confirm_scheme_public_key_dialog_title',
      contentTranslationKey: publicKey,
    );
  }
}

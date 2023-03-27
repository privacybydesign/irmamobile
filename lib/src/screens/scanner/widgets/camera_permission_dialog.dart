import 'package:flutter/widgets.dart';

import 'package:permission_handler/permission_handler.dart';

import '../../../widgets/irma_confirmation_dialog.dart';

class CameraPermissionDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IrmaConfirmationDialog(
      titleTranslationKey: 'qr_scanner.permission_dialog.title',
      contentTranslationKey: 'qr_scanner.permission_dialog.content',
      confirmTranslationKey: 'qr_scanner.permission_dialog.settings',
      onConfirmPressed: () async {
        await openAppSettings();
        Navigator.of(context).pop();
      },
    );
  }
}

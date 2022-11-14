import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../models/session.dart';
import '../../../../widgets/irma_button.dart';
import '../../../../widgets/irma_dialog.dart';
import '../../../../widgets/irma_themed_button.dart';

class DisclosurePermissionConfirmDialog extends StatelessWidget {
  final RequestorInfo requestor;

  const DisclosurePermissionConfirmDialog({
    required this.requestor,
  });

  @override
  Widget build(BuildContext context) {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return IrmaDialog(
      title: FlutterI18n.translate(context, 'disclosure_permission.confirm_dialog.title'),
      content: FlutterI18n.translate(
        context,
        'disclosure_permission.confirm_dialog.explanation',
        translationParams: {
          'requestorName': requestor.name.translate(lang),
        },
      ),
      child: Column(
        children: [
          IrmaButton(
            key: const Key('confirm_share_button'),
            size: IrmaButtonSize.small,
            onPressed: () => Navigator.of(context).pop(true),
            label: 'disclosure_permission.confirm_dialog.confirm',
          ),
          IrmaButton(
            key: const Key('decline_share_button'),
            size: IrmaButtonSize.small,
            onPressed: () => Navigator.of(context).pop(false),
            label: 'disclosure_permission.confirm_dialog.decline',
            isSecondary: true,
          ),
        ],
      ),
    );
  }
}

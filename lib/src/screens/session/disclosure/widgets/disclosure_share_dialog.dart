import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../models/session.dart';
import '../../../../widgets/irma_button.dart';
import '../../../../widgets/irma_dialog.dart';
import '../../../../widgets/irma_themed_button.dart';

class DisclosureShareDialog extends StatelessWidget {
  final RequestorInfo requestor;

  final VoidCallback onConfirm;

  const DisclosureShareDialog({
    required this.requestor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return IrmaDialog(
      title: FlutterI18n.translate(context, 'disclosure_permission.confirm.dialog.title'),
      content: FlutterI18n.translate(
        context,
        'disclosure_permission.confirm.dialog.explanation',
        translationParams: {
          'requestorName': requestor.name.translate(lang),
        },
      ),
      child: Column(
        children: [
          IrmaButton(
            size: IrmaButtonSize.small,
            onPressed: onConfirm,
            label: 'disclosure_permission.confirm.dialog.confirm',
          ),
          IrmaButton(
            size: IrmaButtonSize.small,
            onPressed: () => Navigator.of(context).pop(),
            label: 'disclosure_permission.confirm.dialog.decline',
            isSecondary: true,
          ),
        ],
      ),
    );
  }
}

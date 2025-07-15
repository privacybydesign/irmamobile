import 'package:flutter/material.dart';

import 'irma_info_scaffold_body.dart';

enum ErrorType { general, expired, pairingRejected }

class IrmaErrorScaffoldBody extends StatelessWidget {
  static const _translationKeys = {
    ErrorType.general: 'error.types.general',
    ErrorType.expired: 'error.types.expired',
    ErrorType.pairingRejected: 'error.types.pairing_rejected',
  };

  final ErrorType type;
  final String? details;
  final bool reportable;

  const IrmaErrorScaffoldBody({required this.type, this.details, this.reportable = false});

  @override
  Widget build(BuildContext context) {
    return IrmaInfoScaffoldBody(
      imagePath: 'assets/error/general_error_illustration.svg',
      titleTranslationKey: _translationKeys[type]!,
      bodyTranslationKey: reportable == true ? 'error.report' : null,
      linkTranslationKey: details != null ? 'error.button_show_error' : null,
      linkDialogText: details,
    );
  }
}

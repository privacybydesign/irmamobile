import 'package:flutter/material.dart';

import '../screens/error/error_type.dart';
import '../theme/theme.dart';
import 'irma_info_scaffold_body.dart';

class IrmaErrorScaffoldBody extends StatelessWidget {
  static const _translationKeys = {
    ErrorType.general: 'error.types.general',
    ErrorType.expired: 'error.types.expired',
    ErrorType.pairingRejected: 'error.types.pairing_rejected',
  };

  final ErrorType type;
  final String? details;
  final bool reportable;

  const IrmaErrorScaffoldBody({
    required this.type,
    this.details,
    this.reportable = false,
  });

  @override
  Widget build(BuildContext context) {
    return IrmaInfoScaffoldBody(
      icon: Icons.warning_amber_rounded,
      iconColor: IrmaTheme.of(context).error,
      titleKey: _translationKeys[type]!,
      bodyKey: reportable == true ? 'error.report' : null,
      linkKey: details != null ? 'error.button_show_error' : null,
      linkDialogText: details,
    );
  }
}

import "package:material_ui/material_ui.dart";
import "../../package_name.dart";

import "irma_info_scaffold_body.dart";

enum ErrorType { general, expired, pairingRejected, partyValidationFailed }

class IrmaErrorScaffoldBody extends StatelessWidget {
  static const _translationKeys = {
    ErrorType.general: "error.types.general",
    ErrorType.expired: "error.types.expired",
    ErrorType.pairingRejected: "error.types.pairing_rejected",
    ErrorType.partyValidationFailed: "error.types.party_validation_failed",
  };

  /// Body copy that belongs to the error itself rather than to the report
  /// prompt. Only a rejected counterparty has any: the user needs telling that
  /// nothing was shared, and that is not a bug worth reporting.
  static const _bodyTranslationKeys = {
    ErrorType.partyValidationFailed: "error.types.party_validation_failed_body",
  };

  final ErrorType type;
  final String? details;
  final bool reportable;

  const IrmaErrorScaffoldBody({
    super.key,
    required this.type,
    this.details,
    this.reportable = false,
  });

  @override
  Widget build(BuildContext context) {
    return IrmaInfoScaffoldBody(
      imagePath: yiviAsset("error/general_error_illustration.svg"),
      titleTranslationKey: _translationKeys[type]!,
      bodyTranslationKey:
          _bodyTranslationKeys[type] ??
          (reportable == true ? "error.report" : null),
      linkTranslationKey: details != null ? "error.button_show_error" : null,
      linkDialogText: details,
    );
  }
}

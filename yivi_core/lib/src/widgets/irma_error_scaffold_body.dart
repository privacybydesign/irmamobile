import "package:material_ui/material_ui.dart";
import "../../package_name.dart";

import "irma_info_scaffold_body.dart";

enum ErrorType { general, expired, pairingRejected, credentialUnavailable }

class IrmaErrorScaffoldBody extends StatelessWidget {
  static const _translationKeys = {
    ErrorType.general: "error.types.general",
    ErrorType.expired: "error.types.expired",
    ErrorType.pairingRejected: "error.types.pairing_rejected",
    ErrorType.credentialUnavailable: "error.types.credential_unavailable_title",
  };

  // Types that carry their own explanatory body instead of the "report this"
  // prompt: the situation is the request's, not a fault to report.
  static const _bodyTranslationKeys = {
    ErrorType.credentialUnavailable: "error.types.credential_unavailable",
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
          _bodyTranslationKeys[type] ?? (reportable == true ? "error.report" : null),
      linkTranslationKey: details != null ? "error.button_show_error" : null,
      linkDialogText: details,
    );
  }
}

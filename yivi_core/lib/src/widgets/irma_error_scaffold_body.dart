import "package:material_ui/material_ui.dart";
import "../../package_name.dart";

import "irma_info_scaffold_body.dart";

enum ErrorType { general, expired, pairingRejected }

class IrmaErrorScaffoldBody extends StatelessWidget {
  static const _translationKeys = {
    ErrorType.general: "error.types.general",
    ErrorType.expired: "error.types.expired",
    ErrorType.pairingRejected: "error.types.pairing_rejected",
  };

  final ErrorType type;
  final String? details;
  final bool reportable;

  /// Overrides the type's title and the report text, e.g. to say who caused
  /// the error. Both take [translationParams].
  final String? titleTranslationKey;
  final String? bodyTranslationKey;
  final Map<String, String>? translationParams;

  const IrmaErrorScaffoldBody({
    super.key,
    required this.type,
    this.details,
    this.reportable = false,
    this.titleTranslationKey,
    this.bodyTranslationKey,
    this.translationParams,
  });

  @override
  Widget build(BuildContext context) {
    return IrmaInfoScaffoldBody(
      imagePath: yiviAsset("error/general_error_illustration.svg"),
      titleTranslationKey: titleTranslationKey ?? _translationKeys[type]!,
      titleTranslationParams: translationParams,
      bodyTranslationKey:
          bodyTranslationKey ?? (reportable == true ? "error.report" : null),
      bodyTranslationParams: translationParams,
      linkTranslationKey: details != null ? "error.button_show_error" : null,
      linkDialogText: details,
    );
  }
}

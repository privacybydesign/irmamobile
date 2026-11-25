import "package:material_ui/material_ui.dart";
import "../../package_name.dart";

import "../theme/theme.dart";
import "irma_info_scaffold_body.dart";
import "translated_text.dart";

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

  /// Overrides the type's title and the report text, e.g. to say who caused
  /// the error. Both take [translationParams].
  final String? titleTranslationKey;
  final String? bodyTranslationKey;
  final Map<String, String>? translationParams;

  /// Sends the error report to Yivi. Shown as a link, for screens where the
  /// button is "Hulp nodig?": reporting is not asking for help.
  final VoidCallback? onReport;

  /// Says the report went to Yivi, in place of the link.
  final bool reported;

  const IrmaErrorScaffoldBody({
    super.key,
    required this.type,
    this.details,
    this.reportable = false,
    this.titleTranslationKey,
    this.bodyTranslationKey,
    this.translationParams,
    this.onReport,
    this.reported = false,
  });

  @override
  Widget build(BuildContext context) {
    return IrmaInfoScaffoldBody(
      imagePath: yiviAsset("error/general_error_illustration.svg"),
      titleTranslationKey: titleTranslationKey ?? _translationKeys[type]!,
      titleTranslationParams: translationParams,
      bodyTranslationKey:
          bodyTranslationKey ??
          _bodyTranslationKeys[type] ??
          (reportable == true ? "error.report" : null),
      bodyTranslationParams: translationParams,
      linkTranslationKey: details != null ? "error.button_show_error" : null,
      linkDialogText: details,
      footer: _report(context),
    );
  }

  Widget? _report(BuildContext context) {
    final theme = IrmaTheme.of(context);
    if (reported) {
      return TranslatedText(
        "error.report_sent",
        key: const Key("error_report_sent"),
        style: theme.textTheme.bodyMedium,
        textAlign: TextAlign.center,
      );
    }
    final report = onReport;
    if (report == null) return null;
    return GestureDetector(
      key: const Key("error_send_report_link"),
      onTap: () {
        report();
        Feedback.forTap(context);
      },
      child: TranslatedText(
        "error.button_send_report",
        style: theme.textTheme.bodyMedium?.copyWith(
          decoration: TextDecoration.underline,
          color: theme.link,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

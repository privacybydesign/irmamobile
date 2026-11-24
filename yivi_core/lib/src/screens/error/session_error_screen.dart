import "package:material_ui/material_ui.dart";

import "../../models/session.dart";
import "../../util/i18n.dart";
import "../../widgets/feedback/error_status_screen.dart";
import "../need_help/help_problem.dart";
import "../need_help/support_party.dart";
import "blocked_screen.dart";
import "error_screen.dart";
import "no_internet_screen.dart";
import "session_error_cause.dart";

class SessionErrorScreen extends StatelessWidget {
  final SessionError? error;
  final VoidCallback onTapClose;
  final VoidCallback? onTapRetry;

  /// The organisation the session was with, when known. Errors it caused
  /// send the user there; other errors only name it.
  final SupportParty? organisation;

  const SessionErrorScreen({
    required this.error,
    required this.onTapClose,
    this.onTapRetry,
    this.organisation,
  });

  @override
  Widget build(BuildContext context) {
    // Handle internet errors separately
    switch (error?.errorType) {
      case "transport":
        return NoInternetScreen(onTapClose: onTapClose, onTapRetry: onTapRetry);
      case "pairingRejected":
        return ErrorScreen(
          onTapClose: onTapClose,
          type: ErrorType.pairingRejected,
        );
    }

    switch (error?.remoteError?.errorName) {
      case "USER_NOT_FOUND":
      case "USER_NOT_REGISTERED":
        return BlockedScreen();
    }

    final org = organisation;
    final params = org != null ? {"org": org.name} : null;
    final details = error?.toString();
    final report = HelpErrorReport(
      details: details ?? "",
      reportable: error?.reportable ?? false,
    );

    HelpContext help(
      HelpProblem problem,
      String labelKey, {
      String? code,
      String? subtitleKey,
    }) => HelpContext(
      sectionKey: "need_help.context.error_section",
      labelKey: labelKey,
      subtitle: code != null
          ? context.tr("need_help.context.error_code", {"code": code})
          : subtitleKey != null
          ? context.tr(subtitleKey)
          : null,
      problem: problem,
      organisation: org,
      errorCode: code,
      // The error screen offers to send it, and it goes along if the
      // request ends at Yivi.
      errorReport: report,
    );

    return switch (sessionErrorCause(error)) {
      SessionErrorCause.expired => ErrorScreen(
        onTapClose: onTapClose,
        type: ErrorType.expired,
        reportable: false,
        helpContext: help(
          HelpProblems.errorExpired,
          "need_help.context.error_expired",
        ),
      ),
      SessionErrorCause.yivi => ErrorScreen(
        onTapClose: onTapClose,
        details: details,
        reportable: report.reportable,
        titleTranslationKey: "error.types.yivi",
        bodyTranslationKey: org != null
            ? "error.types.yivi_body"
            : "error.types.yivi_body_no_organisation",
        translationParams: params,
        helpContext: help(
          HelpProblems.errorYivi,
          "need_help.context.error_yivi",
        ),
      ),
      // Yivi wants to know about these too, to tell the organisation before
      // its users do.
      SessionErrorCause.organisation => ErrorScreen(
        onTapClose: onTapClose,
        details: details,
        reportable: report.reportable,
        titleTranslationKey: org != null
            ? "error.types.organisation"
            : "error.types.organisation_unknown",
        bodyTranslationKey: "error.types.organisation_body",
        translationParams: params,
        helpContext: help(
          HelpProblems.errorOrganisation,
          "need_help.context.error_organisation",
          code: sessionErrorCode(error),
        ),
      ),
      SessionErrorCause.unknown => ErrorScreen(
        onTapClose: onTapClose,
        details: details,
        reportable: report.reportable,
        bodyTranslationKey: org != null
            ? "error.types.unknown_body"
            : "error.types.unknown_body_no_organisation",
        translationParams: params,
        helpContext: help(
          HelpProblems.errorUnknown,
          "need_help.context.error_unknown",
          subtitleKey: "need_help.context.error_unknown_subtitle",
        ),
      ),
    };
  }
}

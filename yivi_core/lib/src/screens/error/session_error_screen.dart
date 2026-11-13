import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../models/session.dart";
import "../../widgets/irma_error_scaffold_body.dart";
import "../error/blocked_screen.dart";
import "../error/error_screen.dart";
import "../error/no_internet_screen.dart";
import "../need_help/help_problem.dart";
import "../need_help/support_party.dart";
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
          ? FlutterI18n.translate(
              context,
              "need_help.context.error_code",
              translationParams: {"code": code},
            )
          : subtitleKey != null
          ? FlutterI18n.translate(context, subtitleKey)
          : null,
      problem: problem,
      organisation: org,
      errorCode: code,
      // Goes along only if the request ends at Yivi.
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
      SessionErrorCause.organisation => ErrorScreen(
        onTapClose: onTapClose,
        details: details,
        reportable: false,
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

import "package:material_ui/material_ui.dart";

import "../../models/session.dart";
import "../../widgets/irma_error_scaffold_body.dart";
import "../error/blocked_screen.dart";
import "../error/error_screen.dart";
import "../error/no_internet_screen.dart";

class SessionErrorScreen extends StatelessWidget {
  final SessionError? error;
  final VoidCallback onTapClose;
  final VoidCallback? onTapRetry;

  const SessionErrorScreen({
    required this.error,
    required this.onTapClose,
    this.onTapRetry,
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

    // A disclosure request (e.g. over the Digital Credentials API) asked for a
    // credential the wallet cannot satisfy and cannot obtain: the core reports
    // no handler for the credential query. Say so plainly instead of showing a
    // generic, reportable failure — there is nothing for the user to report.
    if (error?.wrappedError.contains("no credential query handler") ?? false) {
      return ErrorScreen(
        onTapClose: onTapClose,
        type: ErrorType.credentialUnavailable,
        reportable: false,
      );
    }

    switch (error?.remoteError?.errorName) {
      case "USER_NOT_FOUND":
      case "USER_NOT_REGISTERED":
        return BlockedScreen();
      case "SESSION_UNKNOWN":
        return ErrorScreen(onTapClose: onTapClose, type: ErrorType.expired);
      case "UNEXPECTED_REQUEST":
        return ErrorScreen(onTapClose: onTapClose, type: ErrorType.expired);
    }

    return ErrorScreen(
      details: error?.toString(),
      reportable: error?.reportable ?? false,
      onTapClose: onTapClose,
    );
  }
}

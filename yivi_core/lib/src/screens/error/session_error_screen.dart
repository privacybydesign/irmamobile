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
      // irmago types this separately from every other failure so the app can
      // say the counterparty was rejected and nothing was shared, rather than
      // implying the app itself broke. A party that merely fails to be vouched
      // for never lands here — that is a low trust level, and the session runs.
      case "party_validation_failed":
        return ErrorScreen(
          onTapClose: onTapClose,
          type: ErrorType.partyValidationFailed,
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

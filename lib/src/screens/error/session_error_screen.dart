import 'package:flutter/material.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/screens/error/blocked_screen.dart';
import 'package:irmamobile/src/screens/error/session_expired_screen.dart';
import 'package:irmamobile/src/sentry/sentry.dart';

import 'error_screen.dart';
import 'no_internet_screen.dart';

class SessionErrorScreen extends StatelessWidget {
  final SessionError error;
  final VoidCallback onTapClose;
  final VoidCallback onTapRetry;

  const SessionErrorScreen({@required this.error, @required this.onTapClose, this.onTapRetry});

  @override
  Widget build(BuildContext context) {
    // Handle internet errors separately
    if (error.errorType == 'transport') {
      return NoInternetScreen(
        onTapClose: onTapClose,
        onTapRetry: onTapRetry,
      );
    } else if (error.remoteError != null && error.remoteError.errorName == "USER_NOT_FOUND") {
      return BlockedScreen();
    } else if (error.remoteError != null && error.remoteError.errorName == "SESSION_UNKNOWN") {
      return SessionExpiredScreen(onTapClose: onTapClose);
    } else if (error.remoteError != null && error.remoteError.errorName == "UNEXPECTED_REQUEST") {
      return SessionExpiredScreen(onTapClose: onTapClose);
    } else {
      return GeneralErrorScreen(
        errorText: error.toString(),
        onTapClose: onTapClose,
        onTapReport: () => reportError(error, null, userInitiated: true),
      );
    }
  }
}

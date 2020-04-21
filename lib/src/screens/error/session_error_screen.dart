import 'package:flutter/material.dart';
import 'package:irmamobile/src/models/session.dart';
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
    } else {
      return GeneralErrorScreen(
        errorText: error.toString(),
        onTapClose: onTapClose,
        onTapReport: () => reportError(error, null, userInitiated: true),
      );
    }
  }
}

import 'package:flutter/material.dart';

import '../../models/session.dart';
import '..//error/error_screen.dart';
import '..//error/no_internet_screen.dart';
import '../error/blocked_screen.dart';

class SessionErrorScreen extends StatelessWidget {
  final SessionError? error;
  final VoidCallback onTapClose;
  final VoidCallback? onTapRetry;

  const SessionErrorScreen({required this.error, required this.onTapClose, this.onTapRetry});

  @override
  Widget build(BuildContext context) {
    // Handle internet errors separately
    switch (error?.errorType) {
      case 'transport':
        return NoInternetScreen(onTapClose: onTapClose, onTapRetry: onTapRetry);
      case 'pairingRejected':
        return ErrorScreen(onTapClose: onTapClose, type: ErrorType.pairingRejected, reportable: false);
    }

    switch (error?.remoteError?.errorName) {
      case "USER_NOT_FOUND":
        return BlockedScreen();
      case "SESSION_UNKNOWN":
        return ErrorScreen(onTapClose: onTapClose, type: ErrorType.expired, reportable: false);
      case "UNEXPECTED_REQUEST":
        return ErrorScreen(onTapClose: onTapClose, type: ErrorType.expired, reportable: false);
    }

    return ErrorScreen(
      details: error?.toString(),
      reportable: error?.reportable ?? false,
      onTapClose: onTapClose,
    );
  }
}

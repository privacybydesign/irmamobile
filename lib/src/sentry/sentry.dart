import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:irmamobile/sentry_dsn.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:sentry/sentry.dart';

final _sentry = dsn != '' ? SentryClient(dsn: dsn, environmentAttributes: const Event(release: version)) : null;

Future<void> reportError(dynamic error, dynamic stackTrace, {bool userInitiated = false}) async {
  // Print the exception to the console.
  if (_sentry == null) {
    // Print the full stacktrace when not provided with dsn
    debugPrint(error.toString());
    if (stackTrace != null) debugPrint(stackTrace.toString());
  } else {
    final enabled = await IrmaPreferences.get().getReportErrors().first;
    // Send the Exception and Stacktrace to Sentry when enabled
    if (enabled || userInitiated) {
      _sentry.capture(
        event: Event(
          exception: error,
          stackTrace: stackTrace,
          tags: {
            "OS": Platform.operatingSystem,
            "OS Version": Platform.operatingSystemVersion,
          },
        ),
      );
    }
  }
}

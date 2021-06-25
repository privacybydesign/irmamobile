import 'dart:io';

/* TODO: Migrate to new Sentry version
import 'package:flutter/foundation.dart';
import 'package:irmamobile/sentry_dsn.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:sentry/sentry.dart';

final _sentry = dsn != '' ? SentryClient(SentryOptions(dsn: dsn)) : null;
*/
Future<void> reportError(dynamic error, dynamic stackTrace, {bool userInitiated = false}) async {
  // Print the exception to the console.
  /*if (_sentry == null) {
    // Print the full stacktrace when not provided with dsn
    debugPrint(error.toString());
    if (stackTrace != null) debugPrint(stackTrace.toString());
  } else {
    final enabled = await IrmaPreferences.get().getReportErrors().first;
    // Send the Exception and Stacktrace to Sentry when enabled
    if (enabled || userInitiated) {
      _sentry.captureEvent(
        SentryEvent(
          throwable: error,
          stackTrace: SentryStackTrace(stackTrace),
          release: version,
          tags: {
            "OS": Platform.operatingSystem,
            "OS Version": Platform.operatingSystemVersion,
          },
        ),
      );
    }*/
}

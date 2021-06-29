import 'package:flutter/foundation.dart';
import 'package:irmamobile/sentry_dsn.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> initSentry() async {
  if (dsn != '') {
    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
      },
    );
  }
}

Future<void> reportError(dynamic error, dynamic stackTrace, {bool userInitiated = false}) async {
  // Print the exception to the console.
  if (dsn == '') {
    // Print the full stacktrace when not provided with dsn
    debugPrint(error.toString());
    if (stackTrace != null) debugPrint(stackTrace.toString());
  } else {
    final enabled = await IrmaPreferences.get().getReportErrors().first;
    // Send the Exception and Stacktrace to Sentry when enabled
    if (enabled || userInitiated) {
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );
    }
  }
}

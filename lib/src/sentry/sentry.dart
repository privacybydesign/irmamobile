import 'package:irmamobile/sentry_dsn.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:sentry/sentry.dart';

final _sentry = dsn != '' ? SentryClient(dsn: dsn) : null;

Future<void> reportError(dynamic error, dynamic stackTrace, {bool userInitiated = false}) async {
  // Print the exception to the console.
  if (_sentry == null) {
    // Print the full stacktrace in debug mode.
    print(error);
    print(stackTrace);
  } else {
    final enabled = await IrmaPreferences.get().getReportErrors().first;
    // Send the Exception and Stacktrace to Sentry in Production mode (if user has it enabled)
    if (enabled || userInitiated) {
      _sentry.captureException(
        exception: error,
        stackTrace: stackTrace,
      );
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:irmamobile/sentry_dsn.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:package_info/package_info.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> initSentry() async {
  if (dsn != '') {
    await SentryFlutter.init(
      (options) async {
        // Build number is automatically set by Sentry via the 'dist' tag.
        final release = await PackageInfo.fromPlatform().then((info) => info.version).catchError((_) => version);
        options.release = release;
        options.dsn = dsn;
        options.enableNativeCrashHandling = await IrmaPreferences.get().getReportErrors().first;
        // In the privacy policy we only mention error events, so we don't send the session health information.
        options.enableAutoSessionTracking = false;
      },
    );
    Sentry.configureScope((scope) => scope.setTag('git', version));
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

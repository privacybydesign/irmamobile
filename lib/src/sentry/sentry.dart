import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:package_info/package_info.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../sentry_dsn.dart';
import '../data/irma_preferences.dart';

Future<void> initSentry({required IrmaPreferences preferences}) async {
  if (dsn != '') {
    final completer = Completer();
    // Keep listening to make sure preference changes are immediately processed.
    preferences.getReportErrors().listen((reportErrors) async {
      if (Sentry.isEnabled) await Sentry.close();
      await SentryFlutter.init(
        (options) async {
          // Build number is automatically set by Sentry via the 'dist' tag.
          final release = await PackageInfo.fromPlatform().then((info) => info.version).catchError((_) => version);
          options.release = release;
          options.dsn = dsn;
          options.enableNativeCrashHandling = reportErrors;
          // In the privacy policy we only mention error events, so we don't send the session health information.
          options.enableAutoSessionTracking = false;
        },
      );
      Sentry.configureScope((scope) => scope.setTag('git', version));
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
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

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../sentry_dsn.dart';
import '../data/irma_preferences.dart';
import 'stub_platform_checker.dart';

// this is a global because it needs to be available before the preferences have even initialized
bool _reportErrorsPreferenceValue = false;

Future<void> initSentry({required IrmaPreferences preferences}) async {
  if (dsn != '') {
    final completer = Completer();
    // Keep listening to make sure preference changes are immediately processed.
    preferences.getReportErrors().listen((reportErrors) async {
      _reportErrorsPreferenceValue = reportErrors;
      if (Sentry.isEnabled) await Sentry.close();
      await SentryFlutter.init(
        (options) async {
          // Build number is automatically set by Sentry via the 'dist' tag.
          final release = await PackageInfo.fromPlatform().then((info) => info.version).catchError((_) => version);
          options.release = release;
          options.dsn = dsn;
          options.enableNativeCrashHandling = reportErrors;

          // Enable app health check
          options.enableAutoSessionTracking = reportErrors;

          // As noted in the docs of enableNativeCrashHandling, platform checking does not work on iOS when
          // native crash handling is disabled. Therefore, we add a fallback implementation.
          if (!options.enableNativeCrashHandling && Platform.isIOS) options.platformChecker = StubPlatformChecker();
        },
      );
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
  }
}

Future<void> reportError(dynamic error, dynamic stackTrace, {bool userInitiated = false}) async {
  // If Sentry is not configured, we report the error to Flutter such that the test framework can detect it.
  if (dsn == '') {
    final supportsDefaultStackFilter = stackTrace == null || stackTrace is StackTrace;
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: supportsDefaultStackFilter ? stackTrace : StackTrace.fromString(stackTrace.toString()),
      stackFilter: supportsDefaultStackFilter ? FlutterError.defaultStackFilter : (frames) => frames,
    ));
  } else {
    // Send the Exception and Stacktrace to Sentry when enabled
    if (_reportErrorsPreferenceValue || userInitiated) {
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );
    }
  }
}

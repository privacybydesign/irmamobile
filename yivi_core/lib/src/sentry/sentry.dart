import "dart:async";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:sentry_flutter/sentry_flutter.dart";

import "../../sentry_dsn.dart";
import "../data/irma_preferences.dart";
import "stub_runtime_checker.dart";

// this is a global because it needs to be available before the preferences have even initialized
bool _reportErrorsPreferenceValue = false;

/// How many reports the user asked for are being sent right now. Those go out
/// even when the user did not opt in to automatic reporting.
int _userInitiatedReports = 0;

/// Whether [event] may leave the device: only when the user opted in to error
/// reporting, or asked for this one report to be sent.
///
/// Sentry reports uncaught framework and platform errors by itself once it is
/// initialised, without going through [reportError]. This check is what keeps
/// those on the device of a user who did not opt in.
@visibleForTesting
bool mayLeaveDevice() =>
    _reportErrorsPreferenceValue || _userInitiatedReports > 0;

@visibleForTesting
void setReportErrorsForTesting(bool value) =>
    _reportErrorsPreferenceValue = value;

/// Runs [report] as a report the user asked for.
@visibleForTesting
Future<T> asUserInitiated<T>(Future<T> Function() report) async {
  _userInitiatedReports++;
  try {
    return await report();
  } finally {
    _userInitiatedReports--;
  }
}

Future<void> _startSentry({required bool reportErrors}) async {
  await SentryFlutter.init((options) async {
    // Build number is automatically set by Sentry via the 'dist' tag.
    final release = await PackageInfo.fromPlatform()
        .then((info) => info.version)
        .catchError((_) => version);
    options.release = release;
    options.dsn = dsn;
    options.enableNativeCrashHandling = reportErrors;

    // Enable app health check
    options.enableAutoSessionTracking = reportErrors;

    // No IP address, user or device identifiers beyond what a crash report needs.
    options.sendDefaultPii = false;
    options.beforeSend = (event, hint) => mayLeaveDevice() ? event : null;

    // As noted in the docs of enableNativeCrashHandling, platform checking does not work on iOS when
    // native crash handling is disabled. Therefore, we add a fallback implementation.
    if (!options.enableNativeCrashHandling && Platform.isIOS) {
      options.runtimeChecker = StubRuntimeChecker();
    }
  });
}

/// Sentry is only started once the user opts in to error reporting. Until then
/// nothing is initialised, so nothing can be sent. A report the user asks for
/// on an error screen starts it on demand, see [_ensureStartedForUserReport].
Future<void> initSentry({required IrmaPreferences preferences}) async {
  if (dsn != "") {
    final completer = Completer();
    // Keep listening to make sure preference changes are immediately processed.
    preferences.getReportErrors().listen((reportErrors) async {
      _reportErrorsPreferenceValue = reportErrors;
      if (Sentry.isEnabled) await Sentry.close();
      if (reportErrors) await _startSentry(reportErrors: true);
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
  }
}

/// Starts Sentry for a report the user asked for while not opted in. Native
/// crash handling and session tracking stay off, and [mayLeaveDevice] drops
/// everything except reports the user asks for.
Future<void> _ensureStartedForUserReport() async {
  if (!Sentry.isEnabled) await _startSentry(reportErrors: false);
}

/// Reports a message to Sentry at the info log level if the user gave permission
Future<void> reportFeedback(
  String message, {
  bool userInitiated = false,
}) async {
  if (dsn != "") {
    if (userInitiated) {
      await _ensureStartedForUserReport();
      await asUserInitiated(() => Sentry.captureMessage(message));
    } else if (_reportErrorsPreferenceValue) {
      Sentry.captureMessage(message);
    }
  }
  if (kDebugMode) {
    debugPrint("report feedback: $message");
  }
}

/// Reports a the error to Sentry if the user gave permission
Future<void> reportError(
  dynamic error,
  dynamic stackTrace, {
  bool userInitiated = false,
}) async {
  // If Sentry is not configured, we report the error to Flutter such that the test framework can detect it.
  if (dsn == "") {
    final supportsDefaultStackFilter =
        stackTrace == null || stackTrace is StackTrace;
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: supportsDefaultStackFilter
            ? stackTrace
            : StackTrace.fromString(stackTrace.toString()),
        stackFilter: supportsDefaultStackFilter
            ? FlutterError.defaultStackFilter
            : (frames) => frames,
      ),
    );
  } else {
    // Send the Exception and Stacktrace to Sentry when enabled
    if (userInitiated) {
      await _ensureStartedForUserReport();
      await asUserInitiated(
        () => Sentry.captureException(error, stackTrace: stackTrace),
      );
    } else if (_reportErrorsPreferenceValue) {
      Sentry.captureException(error, stackTrace: stackTrace);
    }
  }
}

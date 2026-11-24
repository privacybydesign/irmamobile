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

    // Native events do not pass beforeSend below, and on iOS these two are not
    // tied to enableNativeCrashHandling.
    options.enableAppHangTracking = reportErrors;
    options.enableWatchdogTerminationTracking = reportErrors;

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
/// on an error screen starts it for that report only, see [sendUserInitiated].
Future<void> initSentry({required IrmaPreferences preferences}) async {
  if (dsn != "") {
    final completer = Completer();
    // Keep listening to make sure preference changes are immediately processed.
    preferences.reportErrors.stream.listen((reportErrors) async {
      _reportErrorsPreferenceValue = reportErrors;
      if (Sentry.isEnabled) await Sentry.close();
      if (reportErrors) await _startSentry(reportErrors: true);
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
  }
}

/// The parts of Sentry that [sendUserInitiated] starts and stops, so a test
/// can stand in for them.
@visibleForTesting
class SentryLifecycle {
  final bool Function() isEnabled;
  final Future<void> Function() start;
  final Future<void> Function() close;

  const SentryLifecycle({
    required this.isEnabled,
    required this.start,
    required this.close,
  });
}

/// Native crash handling, session, app-hang and watchdog tracking stay off for
/// a start without the opt-in.
final _realSentry = SentryLifecycle(
  isEnabled: () => Sentry.isEnabled,
  start: () => _startSentry(reportErrors: false),
  close: Sentry.close,
);

/// Sends a [report] the user asked for. Without the opt-in Sentry is started
/// for this report only and closed again once it is sent: while it runs,
/// [mayLeaveDevice] only filters what goes through Dart, and nothing should
/// depend on that for longer than the report takes.
@visibleForTesting
Future<void> sendUserInitiated(
  Future<void> Function() report, {
  SentryLifecycle? sentry,
}) async {
  sentry ??= _realSentry;
  // Counted from before the start, so a report that finishes while another is
  // still starting does not close Sentry under it.
  _userInitiatedReports++;
  try {
    if (!sentry.isEnabled()) await sentry.start();
    await report();
  } finally {
    _userInitiatedReports--;
    // The preference is read now, not before the report: the user may have
    // opted in while it was being sent.
    if (_userInitiatedReports == 0 &&
        !_reportErrorsPreferenceValue &&
        sentry.isEnabled()) {
      await sentry.close();
    }
  }
}

/// Reports a message to Sentry at the info log level if the user gave permission
Future<void> reportFeedback(
  String message, {
  bool userInitiated = false,
}) async {
  if (dsn != "") {
    if (userInitiated) {
      await sendUserInitiated(() => Sentry.captureMessage(message));
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
      await sendUserInitiated(
        () => Sentry.captureException(error, stackTrace: stackTrace),
      );
    } else if (_reportErrorsPreferenceValue) {
      Sentry.captureException(error, stackTrace: stackTrace);
    }
  }
}

import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/sentry/sentry.dart";

/// Stands in for Sentry: remembers whether it runs and how often it was started.
class _FakeSentry {
  bool enabled;
  int starts = 0;

  _FakeSentry({this.enabled = false});

  SentryLifecycle get lifecycle => SentryLifecycle(
    isEnabled: () => enabled,
    start: () async {
      starts++;
      enabled = true;
    },
    close: () async => enabled = false,
  );
}

/// Sentry reports uncaught errors by itself once it runs, so every event passes
/// one check before it may leave the device, and without the opt-in Sentry only
/// runs for as long as a report the user asked for takes.
void main() {
  tearDown(() => setReportErrorsForTesting(false));

  test("nothing leaves the device of a user who did not opt in", () {
    setReportErrorsForTesting(false);
    expect(mayLeaveDevice(), isFalse);
  });

  test("events leave the device once the user opted in", () {
    setReportErrorsForTesting(true);
    expect(mayLeaveDevice(), isTrue);
  });

  test("a report the user asks for goes out without the opt-in, and only "
      "that report", () async {
    setReportErrorsForTesting(false);
    final sentry = _FakeSentry();

    late bool duringReport;
    await sendUserInitiated(
      () async => duringReport = sentry.enabled && mayLeaveDevice(),
      sentry: sentry.lifecycle,
    );

    expect(duringReport, isTrue);
    expect(mayLeaveDevice(), isFalse);
  });

  test("Sentry is closed again after a report the user asked for without "
      "the opt-in", () async {
    setReportErrorsForTesting(false);
    final sentry = _FakeSentry();

    await sendUserInitiated(() async {}, sentry: sentry.lifecycle);

    expect(sentry.starts, 1);
    expect(sentry.enabled, isFalse);
  });

  test("Sentry is closed and the exception ends when sending the report "
      "fails", () async {
    setReportErrorsForTesting(false);
    final sentry = _FakeSentry();

    await expectLater(
      sendUserInitiated(
        () async => throw StateError("offline"),
        sentry: sentry.lifecycle,
      ),
      throwsStateError,
    );

    expect(mayLeaveDevice(), isFalse);
    expect(sentry.enabled, isFalse);
  });

  test("Sentry keeps running after a report of a user who opted in", () async {
    setReportErrorsForTesting(true);
    final sentry = _FakeSentry(enabled: true);

    await sendUserInitiated(() async {}, sentry: sentry.lifecycle);

    expect(sentry.starts, 0);
    expect(sentry.enabled, isTrue);
  });

  test("Sentry keeps running when the user opts in while the report is "
      "being sent", () async {
    setReportErrorsForTesting(false);
    final sentry = _FakeSentry();

    await sendUserInitiated(
      () async => setReportErrorsForTesting(true),
      sentry: sentry.lifecycle,
    );

    expect(sentry.enabled, isTrue);
  });

  test("a report that finishes first does not close Sentry under one that "
      "is still being sent", () async {
    setReportErrorsForTesting(false);
    final sentry = _FakeSentry();

    late bool enabledAfterFirst;
    await sendUserInitiated(() async {
      await sendUserInitiated(() async {}, sentry: sentry.lifecycle);
      enabledAfterFirst = sentry.enabled;
    }, sentry: sentry.lifecycle);

    expect(enabledAfterFirst, isTrue);
    expect(sentry.enabled, isFalse);
  });
}

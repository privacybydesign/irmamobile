import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/sentry/sentry.dart";

/// Sentry reports uncaught errors by itself once it runs, so every event passes
/// one check before it may leave the device.
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

    final duringReport = await asUserInitiated(() async => mayLeaveDevice());

    expect(duringReport, isTrue);
    expect(mayLeaveDevice(), isFalse);
  });

  test("the exception for a user's own report ends when sending it "
      "fails", () async {
    setReportErrorsForTesting(false);

    await expectLater(
      asUserInitiated<void>(() async => throw StateError("offline")),
      throwsStateError,
    );

    expect(mayLeaveDevice(), isFalse);
  });
}

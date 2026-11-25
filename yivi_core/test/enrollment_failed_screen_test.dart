import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/screens/enrollment/enrollment_failed_screen.dart";

import "support/onboarding_v2_harness.dart";

void main() {
  late IrmaRepository repo;

  setUp(() async {
    repo = IrmaRepository(
      client: RecordingBridge(),
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

  Future<void> pumpFailed(WidgetTester tester, SessionError error) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await pumpHome(
      tester,
      repo: repo,
      home: EnrollmentFailedScreen(
        error: error,
        onPrevious: () {},
        onRetryEnrollment: () {},
      ),
    );
    await settle(tester);
  }

  testWidgets("says why setting up failed, and shows the whole error", (
    tester,
  ) async {
    final error = SessionError(
      errorType: "serverResponse",
      info: "keyshare registration",
      wrappedError: "unexpected status 500",
      remoteStatus: 500,
      remoteError: RemoteError(
        status: 500,
        errorName: "EXCEPTION",
        description: "The keyshare server could not store the account",
      ),
    );
    await pumpFailed(tester, error);

    expect(
      find.text(
        "Yivi could not set up your app: "
        "The keyshare server could not store the account",
      ),
      findsOneWidget,
    );
    expect(find.text("Something went wrong."), findsNothing);

    await tester.tap(find.byKey(const Key("error_details_toggle")));
    await settle(tester);
    expect(find.text(error.toString()), findsOneWidget);
  });

  testWidgets("without internet, says so", (tester) async {
    await pumpFailed(
      tester,
      SessionError(errorType: "transport", info: "dial tcp: no route"),
    );
    expect(find.text("No internet connection"), findsOneWidget);
  });

  test("the reason: the server's word first, then what lies underneath", () {
    expect(
      enrollmentFailureReason(
        SessionError(errorType: "x", info: "i", wrappedError: "w"),
      ),
      "w",
    );
    expect(
      enrollmentFailureReason(SessionError(errorType: "x", info: "i")),
      "i",
    );
    expect(
      enrollmentFailureReason(SessionError(errorType: "x", info: "")),
      "x",
    );
  });
}

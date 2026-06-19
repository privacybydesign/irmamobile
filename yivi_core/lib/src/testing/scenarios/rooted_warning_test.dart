import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "../../models/enrollment_status.dart";
import "../../screens/enrollment/enrollment_screen.dart";
import "../../screens/rooted_warning/rooted_warning_screen.dart";

import "../helpers/helpers.dart";
import "../irma_binding.dart";
import "../util.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();

  group("rooted device warning", () {
    setUp(
      () => irmaBinding.setUp(enrollmentStatus: EnrollmentStatus.unenrolled),
    );
    tearDown(() => irmaBinding.tearDown());

    testWidgets(
      "shows warning on rooted device, dismisses on accept, continues to enrollment",
      (tester) async {
        await pumpYiviApp(tester, irmaBinding.repository, isDeviceRooted: true);

        // Warning is shown.
        final acceptButtonFinder = find.byKey(
          const Key("warning_screen_accept_button"),
        );
        await tester.waitFor(acceptButtonFinder);
        expect(find.byType(RootedWarningScreen), findsOneWidget);

        // Accept the risk.
        await tester.tapAndSettle(acceptButtonFinder);

        // Warning is gone, enrollment intro is reached.
        expect(find.byType(RootedWarningScreen), findsNothing);
        await tester.waitFor(find.byType(EnrollmentScreen));
      },
    );
  });
}

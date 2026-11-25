import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/enrollment_status.dart";
import "package:yivi_core/src/screens/enrollment/enrollment_screen.dart";
import "package:yivi_core/src/screens/enrollment/error_reports/enrollment_error_reports_screen.dart";
import "package:yivi_core/src/screens/enrollment/pin/enrollment_pin_page.dart";
import "package:yivi_core/src/screens/enrollment/terms/enrollment_terms_screen.dart";
import "package:yivi_core/src/screens/enrollment/welcome/welcome_screen.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/widgets/sheet/sheet.dart";

import "helpers/helpers.dart";
import "irma_binding.dart";
import "util.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("enrollment", () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(
      () => irmaBinding.setUp(enrollmentStatus: EnrollmentStatus.unenrolled),
    );
    tearDown(() => irmaBinding.tearDown());

    final startFinder = find.byKey(const Key("enrollment_next_button"));
    final acceptFinder = find.byKey(const Key("enrollment_terms_continue"));
    final shareFinder = find.byKey(const Key("error_reports_share"));
    final dontShareFinder = find.byKey(const Key("error_reports_dont_share"));

    // Pumps an unenrolled app with english locale
    Future<void> initEnrollment(WidgetTester tester) async {
      await pumpYiviApp(tester, irmaBinding.repository);
      expect(find.byType(EnrollmentScreen), findsOneWidget);
    }

    Future<void> goThroughWelcome(WidgetTester tester) async {
      expect(find.byType(WelcomeScreen), findsOneWidget);
      await tester.scrollUntilVisible(startFinder.hitTestable(), 50);
      await tester.tapAndSettle(startFinder);
      expect(find.byType(EnrollmentTermsScreen), findsOneWidget);
      await tester.tapAndSettle(acceptFinder);
      expect(find.byType(EnrollmentErrorReportsScreen), findsOneWidget);
      await tester.tapAndSettle(dontShareFinder);
    }

    Future<void> choosePin(WidgetTester tester, [String pin = "12345"]) async {
      expect(find.byType(EnrollmentPinPage), findsOneWidget);
      expect(find.byKey(const Key("pin_chosen_row")), findsNothing);
      await enterPin(tester, pin);
      // A weak PIN goes on by the PIN field's arrow.
      await tester.tapAndSettle(find.byKey(const Key("pin_next")));
    }

    testWidgets("welcome, terms and error reports", (tester) async {
      await initEnrollment(tester);

      expect(
        find.text("Your digital identity, safe on your phone"),
        findsOneWidget,
      );

      // Get started leads to the terms, step 1.
      await tester.scrollUntilVisible(startFinder.hitTestable(), 50);
      await tester.tapAndSettle(startFinder);
      expect(find.text("Before you start"), findsOneWidget);

      // The terms of use open in a sheet, in short.
      await tester.tapAndSettle(find.byKey(const Key("enrollment_terms_open")));
      expect(find.byKey(const Key("legal_sheet_terms")), findsOneWidget);
      expect(find.byKey(const Key("legal_sheet_read_full")), findsOneWidget);
      Navigator.of(tester.element(find.byType(SheetPage))).pop();
      await tester.pumpAndSettle();

      // Accept and continue records the terms.
      await tester.tapAndSettle(acceptFinder);
      expect(irmaBinding.repository.preferences.acceptedTermsUrl, isNotNull);

      // Step 2: what is sent explains itself in a sheet.
      expect(find.text("Help improve Yivi?"), findsOneWidget);
      await tester.tapAndSettle(find.text("What is sent?"));
      expect(find.text("Reporting details"), findsOneWidget);
      expect(find.byKey(const Key("enrollment_sheet_hero")), findsOneWidget);
      Navigator.of(tester.element(find.byType(SheetPage))).pop();
      await tester.pumpAndSettle();

      expect(
        await irmaBinding.repository.preferences.reportErrors.stream.first,
        isFalse,
      );
      await tester.tapAndSettle(shareFinder);
      expect(
        await irmaBinding.repository.preferences.reportErrors.stream.first,
        isTrue,
      );
      expect(find.byType(EnrollmentPinPage), findsOneWidget);
    });

    testWidgets("choose-pin", (tester) async {
      await initEnrollment(tester);
      await goThroughWelcome(tester);
      await choosePin(tester);

      // The same again, on the same page: the chosen PIN above it, grey.
      expect(find.byKey(const Key("pin_chosen_row")), findsOneWidget);
      expect(find.text("Enter the same PIN again"), findsOneWidget);

      // A different PIN says so in place, then choosing starts over.
      // The message shows for a moment only: look right after the last
      // digit, before settling (that takes as long, in real time).
      await enterPin(tester, "5432");
      await tester.tap(find.byKey(const Key("number_pad_key_1")));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text("These PINs don't match. Choose one again."),
        findsOneWidget,
      );
      await tester.waitUntilDisappeared(
        find.byKey(const Key("pin_chosen_row")),
      );

      // Choose and confirm again
      await choosePin(tester);
      await enterPin(tester, "12345");

      // Expect that we left the PIN page
      await tester.waitUntilDisappeared(find.byType(EnrollmentPinPage));
    });

    // Without biometrics on the test device and without the MijnYivi link
    // endpoint, the PIN is the last step: the app sets up and opens on the
    // empty Data tab, which points out the Scan button.
    testWidgets("ends on the empty home with the scan tip", (tester) async {
      await initEnrollment(tester);
      await goThroughWelcome(tester);
      await choosePin(tester);
      await enterPin(tester, "12345");

      await tester.waitFor(find.byType(HomeScreen));
      await tester.waitFor(find.text("No data yet"));
      expect(find.byKey(const Key("scan_tip")), findsOneWidget);

      await tester.tapAndSettle(find.byKey(const Key("scan_tip_ok")));
      expect(find.byKey(const Key("scan_tip")), findsNothing);
    });
  });
}

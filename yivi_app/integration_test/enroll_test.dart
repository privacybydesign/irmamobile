import "package:flutter/gestures.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/enrollment_status.dart";
import "package:yivi_core/src/screens/enrollment/choose_pin/choose_pin_screen.dart";
import "package:yivi_core/src/screens/enrollment/confirm_pin/confirm_pin_screen.dart";
import "package:yivi_core/src/screens/enrollment/enrollment_screen.dart";
import "package:yivi_core/src/screens/enrollment/welcome/welcome_screen.dart";
import "package:yivi_core/src/screens/enrollment/welcome/widgets/error_report_switch.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/widgets/glass/glass_sheet.dart";
import "package:yivi_core/src/widgets/glass/pill_buttons.dart";
import "package:yivi_core/src/widgets/irma_dialog.dart";

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
    final termsFinder = find.byKey(const Key("accept_terms_checkbox"));

    // Pumps an unenrolled app with english locale
    Future<void> initEnrollment(WidgetTester tester) async {
      await pumpYiviApp(tester, irmaBinding.repository);
      expect(find.byType(EnrollmentScreen), findsOneWidget);
    }

    Future<void> goThroughWelcome(WidgetTester tester) async {
      expect(find.byType(WelcomeScreen), findsOneWidget);
      await tester.scrollUntilVisible(termsFinder.hitTestable(), 50);
      await tester.tapAndSettle(termsFinder);
      await tester.tapAndSettle(startFinder);
    }

    Future<void> choosePin(WidgetTester tester, [String pin = "12345"]) async {
      expect(find.byType(ChoosePinScreen), findsOneWidget);
      await enterPin(tester, pin);
      // A weak PIN goes on by the PIN field's arrow.
      await tester.tapAndSettle(find.byKey(const Key("pin_next")));
    }

    testWidgets("welcome", (tester) async {
      await initEnrollment(tester);

      expect(
        find.text("Your digital identity, safe on your phone"),
        findsOneWidget,
      );

      // Error reports are off until the switch is turned on.
      final switchFinder = find.byKey(const Key("error_reporting_switch"));
      await tester.scrollUntilVisible(switchFinder.hitTestable(), 50);
      expect(
        await irmaBinding.repository.preferences.getReportErrors().first,
        isFalse,
      );
      await tester.tapAndSettle(switchFinder);
      expect(
        await irmaBinding.repository.preferences.getReportErrors().first,
        isTrue,
      );

      // The first part of the sentence explains what is shared, in a sheet.
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(ErrorReportSwitch),
          matching: find.byType(Text),
        ),
      );
      final link = (text.textSpan as TextSpan).children!.first as TextSpan;
      expect(link.recognizer, isA<TapGestureRecognizer>());
      (link.recognizer as TapGestureRecognizer).onTap!();
      await tester.pumpAndSettle();
      expect(find.byType(GlassSheetPage), findsOneWidget);
      expect(find.text("Error and app status reporting"), findsOneWidget);
      Navigator.of(tester.element(find.byType(GlassSheetPage))).pop();
      await tester.pumpAndSettle();

      // Get started waits for the terms.
      expect(tester.widget<FancyPillButton>(startFinder).onPressed, isNull);
      await tester.scrollUntilVisible(termsFinder.hitTestable(), 50);
      await tester.tapAndSettle(termsFinder);
      expect(tester.widget<FancyPillButton>(startFinder).onPressed, isNotNull);

      await tester.tapAndSettle(startFinder);
      expect(find.byType(ChoosePinScreen), findsOneWidget);
    });

    testWidgets("choose-pin", (tester) async {
      await initEnrollment(tester);
      await goThroughWelcome(tester);
      await choosePin(tester);

      // Confirm pin
      expect(find.byType(ConfirmPinScreen), findsOneWidget);

      // Enter false pin
      await enterPin(tester, "54321");

      // Expect false pin dialog
      final dialogFinder = find.byType(IrmaDialog);
      expect(dialogFinder, findsOneWidget);
      expect(tester.getAllText(dialogFinder), [
        "PIN entered incorrectly",
        "PINs do not match. Choose a new PIN and try again.",
        "OK",
      ]);
      await tester.tapAndSettle(find.text("OK"));

      // Choose and confirm again
      await choosePin(tester);
      await enterPin(tester, "12345");

      // Expect that we left the pin screens
      expect(find.byType(ChoosePinScreen), findsNothing);
      expect(find.byType(ConfirmPinScreen), findsNothing);
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

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/src/models/enrollment_status.dart';
import 'package:irmamobile/src/screens/enrollment/accept_terms/accept_terms_screen.dart';
import 'package:irmamobile/src/screens/enrollment/accept_terms/widgets/error_reporting_check_box.dart';
import 'package:irmamobile/src/screens/enrollment/choose_pin/choose_pin_screen.dart';
import 'package:irmamobile/src/screens/enrollment/confirm_pin/confirm_pin_screen.dart';
import 'package:irmamobile/src/screens/enrollment/enrollment_screen.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/enrollment_instruction.dart';
import 'package:irmamobile/src/screens/home/home_screen.dart';
import 'package:irmamobile/src/widgets/irma_bottom_sheet.dart';
import 'package:irmamobile/src/widgets/irma_close_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/yivi_themed_button.dart';

import 'helpers/helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  final random = Random();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  // The expected instruction text of the enrollment introduction
  const expectedInstructions = [
    [
      'Yivi is an app for your digital identity',
      'Your official name, birthdate, address, social security number and more. Safely stored in your Yivi-app'
    ],
    [
      "With Yivi you're in control over your data",
      "Easy, secure and swift. You're in control of what you're sharing and with whom.",
    ],
    [
      'Securely on your phone',
      'Only you can access the data on your phone. Nobody has access to your transactions, not even Yivi.'
    ]
  ];

  group('enrollment', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() => irmaBinding.setUp(
          enrollmentStatus: EnrollmentStatus.unenrolled,
        ));
    tearDown(() => irmaBinding.tearDown());

    // Reusable finders
    final nextButtonFinder = find.byKey(const Key('enrollment_next_button'));
    final previousButtonFinder = find.byKey(const Key('enrollment_previous_button'));

    // Pumps an unenrolled app with english locale
    Future<void> _initEnrollment(WidgetTester tester) async {
      await pumpIrmaApp(tester, irmaBinding.repository);
      expect(find.byType(EnrollmentScreen), findsOneWidget);
    }

    Future<void> _goThroughIntroduction(WidgetTester tester) async {
      for (var i = 0; i < expectedInstructions.length; i++) {
        await tester.tap(nextButtonFinder);
        await tester.pump(const Duration(milliseconds: 500));
      }
    }

    Future<void> _goThroughChoosePin(WidgetTester tester, [String pin = '12345']) async {
      expect(find.byType(ChoosePinScreen), findsOneWidget);
      await enterPin(tester, pin);
      await tester.tapAndSettle(find.text('Next'));
      await enterPin(tester, pin);
    }

    Future<void> _goThroughTerms(WidgetTester tester) async {
      expect(find.byType(AcceptTermsScreen), findsOneWidget);
      final checkBoxFinder = find.byKey(const Key('accept_terms_checkbox'));
      await tester.scrollUntilVisible(checkBoxFinder.hitTestable(), 50);
      await tester.tapAndSettle(checkBoxFinder);
      await tester.tapAndSettle(nextButtonFinder);
    }

    Future<void> _goToEmailScreen(WidgetTester tester) async {
      await _initEnrollment(tester);
      await _goThroughIntroduction(tester);
      await _goThroughTerms(tester);
      await _goThroughChoosePin(tester);
    }

    testWidgets(
      'introduction',
      (tester) async {
        await _initEnrollment(tester);
        const pumpTime = Duration(milliseconds: 500);

        for (var i = 0; i < expectedInstructions.length; i++) {
          // Try going back, if this is not the first instruction;
          if (i == 0) {
            expect(previousButtonFinder, findsNothing);
          } else {
            await tester.tap(previousButtonFinder);
            await tester.pump(pumpTime);

            await tester.tap(nextButtonFinder);
            await tester.pump(pumpTime);
          }

          // Evaluate the content
          final instructionFinder = find.byType(EnrollmentInstruction);
          final actualCurrentInstructionTexts = tester.getAllText(instructionFinder);
          final expectedCurrentInstructionTexts = [...expectedInstructions[i], if (i != 0) 'Previous', 'Next'];
          expect(actualCurrentInstructionTexts, expectedCurrentInstructionTexts);

          // Go Next step
          await tester.tap(nextButtonFinder);
          await tester.pump(pumpTime);

          // If we go next on the last step, expect that we left the enrollment introduction.
          if (i == expectedInstructions.length) {
            expect(instructionFinder, findsNothing);
          }
        }
      },
    );

    testWidgets('choose-pin', (tester) async {
      await _initEnrollment(tester);
      await _goThroughIntroduction(tester);
      await _goThroughTerms(tester);

      // Choose the pin
      expect(find.byType(ChoosePinScreen), findsOneWidget);
      const pin = '12345';
      await enterPin(tester, pin);
      await tester.tapAndSettle(find.text('Next'));

      // Confirm pin
      expect(find.byType(ConfirmPinScreen), findsOneWidget);

      // Enter false pin
      const falsePin = '54321';
      await enterPin(tester, falsePin);

      // Expect false pin dialog
      var dialogFinder = find.byType(IrmaDialog);
      expect(dialogFinder, findsOneWidget);
      var expectedDialogText = [
        'PIN entered incorrectly',
        'PINs do not match. Choose a new PIN and try again.',
        'OK',
      ];
      final actualDialogText = tester.getAllText(dialogFinder);
      expect(expectedDialogText, actualDialogText);
      await tester.tapAndSettle(find.text('OK'));

      // Enter correct pin
      await enterPin(tester, pin);
      await tester.tapAndSettle(find.text('Next'));

      // Confirm pin
      await enterPin(tester, pin);

      // Expect that we left the pin screens
      expect(find.byType(ChoosePinScreen), findsNothing);
      expect(find.byType(ConfirmPinScreen), findsNothing);
    });

    testWidgets(
      'terms',
      (tester) async {
        await _initEnrollment(tester);
        await _goThroughIntroduction(tester);
        expect(find.byType(AcceptTermsScreen), findsOneWidget);

        // Scroll to the error reporting opt in
        // Note: this is the entire widget (including the text), not just the checkbox
        final errorReportingOptInFinder = find.byType(ErrorReportingCheckBox);
        await tester.scrollUntilVisible(errorReportingOptInFinder, 50);

        // Check the default error reporting value in the preferences
        final defaultReportErrorsValue = await irmaBinding.repository.preferences.getReportErrors().first;
        expect(defaultReportErrorsValue, false);

        // Find the actual checkbox in the ErrorReportingCheckBox widget and assert the value
        final errorReportingCheckBoxFinder = find.descendant(
          of: errorReportingOptInFinder,
          matching: find.byType(Checkbox),
        );
        final defaultErrorReportingCheckBoxValue = tester.widget<Checkbox>(errorReportingCheckBoxFinder).value;
        expect(defaultErrorReportingCheckBoxValue, defaultReportErrorsValue);

        // Now tap the checkbox and check the value again
        await tester.tapAndSettle(errorReportingCheckBoxFinder);

        final updatedReportErrorsValue = await irmaBinding.repository.preferences.getReportErrors().first;
        expect(updatedReportErrorsValue, true);

        final updatedErrorReportingCheckBoxValue = tester.widget<Checkbox>(errorReportingCheckBoxFinder).value;
        expect(updatedErrorReportingCheckBoxValue, updatedReportErrorsValue);

        // We need to do some extra steps to find the text span link in the ErrorReportingCheckBox widget
        final errorReportingTextFinder = find.descendant(
          of: errorReportingOptInFinder,
          matching: find.byType(Text),
        );
        final errorReportingTextWidget = tester.widget<Text>(errorReportingTextFinder);

        // The second text span in the rich text should be the link
        final linkTextSpan = (errorReportingTextWidget.textSpan as TextSpan).children?.elementAt(1) as TextSpan;

        // Expect the recognizer to be a TapGestureRecognizer and tap it
        expect(linkTextSpan.recognizer, isA<TapGestureRecognizer>());
        (linkTextSpan.recognizer as TapGestureRecognizer).onTap?.call();
        await tester.pumpAndSettle();

        // Expect the bottom sheet to be visible
        final bottomSheetFinder = find.byType(IrmaBottomSheet);
        expect(bottomSheetFinder, findsOneWidget);

        // Expect the bottom sheet to contain the correct text
        final expectedErrorReportingBottomSheetText = [
          'Error and app status reporting',
          "By enabling error reporting you're helping us improve the user experience. This option also allows your app to send us a periodic app status message. Of course, we do all of that without having access to your personal information or transactions."
        ];
        final actualErrorReportingBottomSheetText = tester.getAllText(bottomSheetFinder);
        expect(actualErrorReportingBottomSheetText, expectedErrorReportingBottomSheetText);

        // Close the bottom sheet
        final bottomSheetCloseButtonFinder = find.descendant(
          of: bottomSheetFinder,
          matching: find.byType(IrmaCloseButton),
        );
        await tester.tapAndSettle(bottomSheetCloseButtonFinder);

        // Expect the bottom sheet to be gone
        expect(bottomSheetFinder, findsNothing);

        // Next button should be disabled by default
        expect(tester.widget<YiviThemedButton>(nextButtonFinder).onPressed, isNull);

        // Accept the terms checkbox
        final termsCheckBoxFinder = find.byKey(const Key('accept_terms_checkbox'));
        await tester.scrollUntilVisible(termsCheckBoxFinder.hitTestable(), 50);
        await tester.tapAndSettle(termsCheckBoxFinder);

        // Next button should be enabled now
        expect(tester.widget<YiviThemedButton>(nextButtonFinder).onPressed, isNotNull);

        // Continue to next page
        await tester.tapAndSettle(nextButtonFinder);

        // Expect that we left the terms screens
        expect(find.byType(AcceptTermsScreen), findsNothing);
      },
    );

    testWidgets(
      'skip-email',
      (tester) async {
        await _goToEmailScreen(tester);

        // Press skip on the enrollment nav bar
        await tester.tapAndSettle(find.text('Skip'));

        // Expect confirm skip email dialog
        var dialogFinder = find.byType(IrmaDialog);
        expect(dialogFinder, findsOneWidget);
        const expectedDialogText = [
          'Are you sure?',
          'Adding an e-mail address increases safety',
          'Enter an e-mail address',
          'Skip'
        ];

        final actualDialogText = tester.getAllText(dialogFinder);
        expect(actualDialogText, expectedDialogText);

        // Confirm skip
        await tester.tapAndSettle(find.byKey(const Key('dialog_confirm_button')));

        // Wait for home screen
        await tester.waitFor(find.byType(HomeScreen));
      },
    );

    testWidgets(
      'provide-email',
      (tester) async {
        await _goToEmailScreen(tester);

        var emailInputFinder = find.byKey(const Key('email_input_field'));
        var emailInvalidMessageFinder = find.descendant(
          of: emailInputFinder,
          matching: find.text('Invalid e-mail address'),
        );
        expect(emailInvalidMessageFinder, findsNothing);

        // Button should be disabled
        final bottomBarPrimaryButtonFinder = find.byKey(const Key('bottom_bar_primary'));
        expect(tester.widget<YiviThemedButton>(bottomBarPrimaryButtonFinder).onPressed, isNull);

        // Enter first part of the email
        await tester.enterText(emailInputFinder, 'notAnEmail');

        // Invalid email message should appear
        expect(emailInvalidMessageFinder, findsNothing);

        // Enter the rest of the email.
        final seed = random.nextInt(1000000).toString();
        await tester.enterText(emailInputFinder, 'test$seed@example.com');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Button should be enabled
        expect(tester.widget<YiviThemedButton>(bottomBarPrimaryButtonFinder).onPressed, isNotNull);

        // Error message should be gone
        expect(emailInvalidMessageFinder, findsNothing);

        await tester.tapAndSettle(bottomBarPrimaryButtonFinder);

        // Wait for email sent screen
        await tester.waitFor(find.byKey(const Key('email_sent_screen')));
        await tester.tapAndSettle(bottomBarPrimaryButtonFinder);

        // Wait for home screen
        await tester.waitFor(find.byType(HomeScreen));
      },
      // On physical iOS devices we run the integration test in release mode, as instructed.
      // https://github.com/flutter/flutter/tree/main/packages/integration_test#ios-device-testing
      // Flutter has a bug causing enterText to not work in release mode.
      // https://github.com/flutter/flutter/issues/89749
      // For now, we only run this test in debug mode as a work-around.
      skip: !kDebugMode,
    );
  });
}

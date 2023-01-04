// We cannot test using null safety as long as there are widgets that are not migrated yet.
// @dart=2.11

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/main.dart';
import 'package:irmamobile/src/models/enrollment_status.dart';
import 'package:irmamobile/src/screens/enrollment/accept_terms/accept_terms_screen.dart';
import 'package:irmamobile/src/screens/enrollment/choose_pin/choose_pin_screen.dart';
import 'package:irmamobile/src/screens/enrollment/confirm_pin/confirm_pin_screen.dart';
import 'package:irmamobile/src/screens/enrollment/enrollment_screen.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/enrollment_instruction.dart';
import 'package:irmamobile/src/screens/home/home_screen.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';

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
      'With Yivi you\'re in control over your data',
      'Easy, secure and swift. You\'re in control of what you\'re sharing and with whom.',
    ],
    [
      'Securely on your phone',
      'Only you have access to the data on your phone. Nobody has access to your transactions, not even Yivi.'
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
      await tester.pumpWidgetAndSettle(IrmaApp(
        repository: irmaBinding.repository,
        forcedLocale: const Locale('en', 'EN'),
      ));
      expect(find.byType(EnrollmentScreen), findsOneWidget);
    }

    Future<void> _goThroughIntroduction(WidgetTester tester) async {
      for (var i = 0; i < expectedInstructions.length; i++) {
        await tester.tapAndSettle(nextButtonFinder);
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

        for (var i = 0; i < expectedInstructions.length; i++) {
          // Try going back, if this is not the first instruction;
          if (i == 0) {
            expect(previousButtonFinder, findsNothing);
          } else {
            await tester.tapAndSettle(previousButtonFinder);
            await tester.tapAndSettle(nextButtonFinder);
          }

          // Evaluate the content
          final instructionFinder = find.byType(EnrollmentInstruction);
          final actualCurrentInstructionTexts = tester.getAllText(instructionFinder);
          final expectedCurrentInstructionTexts = [
            '${(i + 1).toString()}/${expectedInstructions.length}',
            ...expectedInstructions[i],
            if (i != 0) 'Previous',
            'Next'
          ];
          expect(actualCurrentInstructionTexts, expectedCurrentInstructionTexts);

          // Go Next step
          await tester.tapAndSettle(nextButtonFinder);

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

      //Choose the pin
      expect(find.byType(ChoosePinScreen), findsOneWidget);
      const pin = '12345';
      await enterPin(tester, pin);
      await tester.tapAndSettle(find.text('Next'));

      //Confirm pin
      expect(find.byType(ConfirmPinScreen), findsOneWidget);

      // Enter false pin
      const falsePin = '54321';
      await enterPin(tester, falsePin);

      //Expect false pin dialog
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

        // Next button should be disabled by default
        expect(tester.widget<IrmaButton>(nextButtonFinder).onPressed, isNull);

        // Tap checkbox
        final checkBoxFinder = find.byKey(const Key('accept_terms_checkbox'));
        await tester.scrollUntilVisible(checkBoxFinder.hitTestable(), 50);
        await tester.tapAndSettle(checkBoxFinder);

        // Next button should be enabled now
        expect(tester.widget<IrmaButton>(nextButtonFinder).onPressed, isNotNull);

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
          matching: find.text('Please check your e-mail address, this doesn\'t seem to be a valid e-mail address'),
        );
        expect(emailInvalidMessageFinder, findsNothing);

        // Continue without entering email
        await tester.tapAndSettle(find.text('Next'));
        expect(emailInvalidMessageFinder, findsOneWidget);

        // Enter false e-mail
        await tester.enterText(emailInputFinder, 'thisIsNotAnEmail');
        await tester.tapAndSettle(find.text('Next'));
        expect(emailInvalidMessageFinder, findsOneWidget);

        // Enter valid e-mail
        final seed = random.nextInt(1000000).toString();
        await tester.enterText(emailInputFinder, 'test$seed@example.com');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tapAndSettle(find.text('Next'));

        // Wait for email sent screen
        await tester.waitFor(find.byKey(const Key('email_sent_screen')));
        await tester.tapAndSettle(find.text('Next'));

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

import 'package:flutter_test/flutter_test.dart';

import 'package:irmamobile/src/screens/add_data/add_data_details_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_discon_stepper.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_make_choice_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_share_dialog.dart';
import 'package:irmamobile/src/screens/session/session_screen.dart';
import 'package:irmamobile/src/screens/session/widgets/disclosure_feedback_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_icon_button.dart';

import '../../helpers/helpers.dart';
import '../../irma_binding.dart';
import '../../helpers/issuance_helpers.dart';
import '../../util.dart';

Future<void> optionalsTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Session requesting:
  // Address from iDIN or municipality
  // And optionally mobile number or e-mail address
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.gemeente.address.street", "irma-demo.gemeente.address.houseNumber", "irma-demo.gemeente.address.city" ],
              [ "irma-demo.idin.idin.address" , "irma-demo.idin.idin.city" ]
            ],
            [
              [],
              [ "irma-demo.sidn-pbdf.email.email" ],
              [ "irma-demo.sidn-pbdf.mobilenumber.mobilenumber" ]
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);

  // Dismiss introduction screen.
  await tester.waitFor(find.text('Share your data'));
  await tester.tapAndSettle(find.descendant(of: find.byType(IrmaButton), matching: find.text('Get going')));

  // Expect a disclose stepper
  final disConStepperFinder = find.byType(DisclosureDisconStepper);
  expect(disConStepperFinder, findsOneWidget);

  // Continue and expect the AddDataDetailsScreen
  await tester.tapAndSettle(find.text('Obtain data'));
  expect(find.byType(AddDataDetailsScreen), findsOneWidget);

  // Add one of the required credentials, in this case the address from municipality
  await issueMunicipalityAddress(tester, irmaBinding);

  // Issue wizard should be completed
  expect(find.text('All required data has been added.'), findsOneWidget);
  await tester.tapAndSettle(find.text('Next step'));

  // A card for adding optional data should be present. Tap it.
  final addOptionalDataCardFinder = find.text('Add optional data');
  expect(addOptionalDataCardFinder, findsOneWidget);
  await tester.ensureVisible(addOptionalDataCardFinder);
  await tester.pumpAndSettle();
  await tester.tapAndSettle(addOptionalDataCardFinder);

  // Expect the make choice screen
  expect(find.byType(DisclosurePermissionMakeChoiceScreen), findsOneWidget);

  // Continue and expect the AddDataDetailsScreen
  await tester.tapAndSettle(find.text('Obtain data'));
  expect(find.byType(AddDataDetailsScreen), findsOneWidget);

  // Issue the email
  await issueEmailAddress(tester, irmaBinding);

  // Press done
  await tester.tapAndSettle(find.text('Done'));
  expect(find.byType(DisclosurePermissionMakeChoiceScreen), findsNothing);

  // Optional data section should have a title now
  final optionalDataHeaderFinder = find.text('Optional data');
  expect(optionalDataHeaderFinder, findsOneWidget);

  // The last card should contain text Demo E-mail address
  final optionalCardFinder = find.byType(IrmaCredentialCard).last;
  expect(
    find.descendant(
      of: optionalCardFinder,
      matching: find.text('Demo Email address'),
    ),
    findsOneWidget,
  );

  // Check if this optional card has a remove button
  final optionalCardCloseButtonFinder = find.descendant(
    of: optionalCardFinder,
    matching: find.byType(IrmaIconButton),
  );
  expect(optionalCardCloseButtonFinder, findsOneWidget);

  // Remove the optional credential
  await tester.ensureVisible(optionalCardCloseButtonFinder);
  await tester.pumpAndSettle();
  await tester.tapAndSettle(optionalCardCloseButtonFinder);

  // Optional data section title should be gone now.
  expect(optionalDataHeaderFinder, findsNothing);

  // The add optional data should reappear
  expect(addOptionalDataCardFinder, findsOneWidget);

  // Tap it
  await tester.tapAndSettle(addOptionalDataCardFinder);

  // Make choice screen should reappear
  expect(find.byType(DisclosurePermissionMakeChoiceScreen), findsOneWidget);

  // Select the mobile number option this time
  final mobileNumberHeaderFinder = find.text('Demo Mobile phone number');
  await tester.ensureVisible(mobileNumberHeaderFinder);
  await tester.pumpAndSettle();
  await tester.tapAndSettle(mobileNumberHeaderFinder);

  // Continue and expect the AddDataDetailsScreen
  await tester.tapAndSettle(find.text('Obtain data'));
  expect(find.byType(AddDataDetailsScreen), findsOneWidget);

  await issueMobileNumber(tester, irmaBinding);

  // Press done
  await tester.tapAndSettle(find.text('Done'));

  // Last (optional) card should be phone number now
  expect(
    find.descendant(
      of: optionalCardFinder,
      matching: find.text('Demo Mobile phone number'),
    ),
    findsOneWidget,
  );

  // Continue
  await tester.tapAndSettle(find.text('Share data'));

  // Confirm the dialog
  expect(find.byType(DisclosurePermissionConfirmDialog), findsOneWidget);
  await tester.tapAndSettle(find.text('Share'));

  // Expect the success screen
  final feedbackScreenFinder = find.byType(DisclosureFeedbackScreen);
  expect(feedbackScreenFinder, findsOneWidget);
  expect(
    (feedbackScreenFinder.evaluate().single.widget as DisclosureFeedbackScreen).feedbackType,
    DisclosureFeedbackType.success,
  );
  await tester.tapAndSettle(find.text('OK'));

  // Session flow should be over now
  expect(find.byType(SessionScreen), findsNothing);
}

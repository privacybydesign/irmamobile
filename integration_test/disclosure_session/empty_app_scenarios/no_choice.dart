import 'package:flutter_test/flutter_test.dart';

import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choices_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_share_dialog.dart';
import 'package:irmamobile/src/screens/session/session_screen.dart';
import 'package:irmamobile/src/screens/session/widgets/disclosure_feedback_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';

import '../../helpers/helpers.dart';
import '../../irma_binding.dart';
import '../../helpers/issuance_helpers.dart';
import '../../util.dart';

Future<void> noChoiceTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Session requesting:
  // Full name AND nationality
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.gemeente.personalData.fullname", "irma-demo.gemeente.personalData.nationality" ]
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);

  // Dismiss introduction screen.
  await tester.waitFor(find.text('Share your data'));
  await tester.tapAndSettle(find.descendant(of: find.byType(IrmaButton), matching: find.text('Get going')));

  // First, the missing required disjunctions should be obtained using an issue wizard.
  expect(find.text('Collect data'), findsOneWidget);
  expect(tester.widgetList(find.byType(IrmaCredentialCard)).length, 1);

  await issueMunicipalityPersonalData(tester, irmaBinding);

  // Issue wizard should be completed
  expect(find.text('All required data has been added.'), findsOneWidget);
  await tester.tapAndSettle(find.text('Next step'));

  // Expect the choices screen
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);
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

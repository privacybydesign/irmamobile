import 'package:flutter_test/flutter_test.dart';

import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_discon_stepper.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_issue_wizard_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';

import '../../helpers/helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';

Future<void> nullablesTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ { "type": "irma-demo.IRMATube.member.fullname", "notNull": true} ]
            ]
          ]
        }
      ''';

  await irmaBinding.repository.startTestSession(sessionRequest);

  // Dismiss introduction screen.
  await tester.waitFor(find.text('Share your data'));
  await tester.tapAndSettle(find.descendant(
    of: find.byType(IrmaButton),
    matching: find.text('Get going'),
  ));

  // Expect obtain credential screen
  expect(find.byType(DisclosurePermissionIssueWizardScreen), findsOneWidget);
  expect(find.text('We still need the following data from you:'), findsOneWidget);

  // One stepper should be visible
  expect(find.byType(DisclosureDisconStepper), findsOneWidget);

  // One Credential card should be visible
  final cardsFinder = find.byType(IrmaCredentialCard);
  expect(cardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo IRMATube Member',
    issuerName: 'Demo IRMATube',
    attributes: {}, // TODO Add check for the required/notNull attirbute
    style: IrmaCardStyle.highlighted,
  );

  // TODO Add non matching credential

  // TODO Expect the DisclosurePermissionWrongCredentialsAddedDialog and evaluate it

  // TODO Add matching credential

  // TODO Complete flow
}

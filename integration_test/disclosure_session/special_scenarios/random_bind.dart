import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_issue_wizard_screen.dart';
import 'package:irmamobile/src/screens/session/session_screen.dart';

import '../../helpers/helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';
import '../disclosure_helpers.dart';

Future<void> randomBindTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Disclose election attribute from stempas.
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/signature/v2",
          "message": "Message to be signed by user",
          "disclose": [
            [
              [ "irma-demo.stemmen.stempas.election" ]
            ]
          ]
        }
      ''';
  await irmaBinding.repository.startTestSession(sessionRequest);
  await evaluateIntroduction(tester);

  expect(find.byType(DisclosurePermissionIssueWizardScreen), findsOneWidget);

  expect(find.text('This data cannot be obtained. Please contact Demo Voting Card Issuer to obtain this data.'),
      findsOneWidget);

  await tester.tapAndSettle(find.text('Close'));

  // Session flow should be over now
  expect(find.byType(SessionScreen), findsNothing);

  // TODO: add the succeeding part of random blind session.
}

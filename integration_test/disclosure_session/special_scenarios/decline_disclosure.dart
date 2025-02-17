import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/screens/home/home_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_close_dialog.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_share_dialog.dart';
import 'package:irmamobile/src/widgets/irma_close_button.dart';

import '../../helpers/helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';
import '../disclosure_helpers.dart';

Future<void> declineDisclosure(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Scenario requesting:
  // E-mail address OR nothing
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email" ],
              []
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);
  await evaluateIntroduction(tester);

  // Press share
  await tester.tapAndSettle(find.text('Share data'));

  // Expect confirm share dialog
  final disclosureConfirmDialogFinder = find.byType(DisclosurePermissionConfirmDialog);
  expect(disclosureConfirmDialogFinder, findsOneWidget);

  // Press don't share
  await tester.tapAndSettle(find.text("Don't share"));

  // Dialog should disappear
  expect(disclosureConfirmDialogFinder, findsNothing);

  // Press the close button
  await tester.tapAndSettle(find.byType(IrmaCloseButton));

  // Expect the close dialog
  final disclosureCloseDialogFinder = find.byType(DisclosurePermissionCloseDialog);
  expect(disclosureCloseDialogFinder, findsOneWidget);

  // Press close and dialog should disappear
  await tester.tapAndSettle(find.text('Yes'));
  expect(disclosureCloseDialogFinder, findsNothing);

  // Finally, expect to be back on the home screen
  expect(find.byType(HomeScreen), findsOneWidget);
}

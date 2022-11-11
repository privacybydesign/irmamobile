import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';

import '../../helpers/helpers.dart';
import '../../helpers/issuance_helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';

Future<void> combinedSessionTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(tester, irmaBinding);

  // Email address
  // And signing the message: "Message to be signed by user"
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/issuance/v2",
          "credentials": [{
              "credential" : "irma-demo.sidn-pbdf.uniqueid",
              "attributes": {
                "uniqueid": "1234",
                "organization": "E-mailgilde"
              }
            }],
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email" ]
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

  await Future.delayed(const Duration(seconds: 15));
}

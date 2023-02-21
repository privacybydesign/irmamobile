import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/screens/home/home_screen.dart';
import 'package:irmamobile/src/widgets/yivi_themed_button.dart';

import '../../helpers/helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';
import '../disclosure_helpers.dart';

Future<void> revocationTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Make sure a revoked credential is present.
  final revocationKey = generateRevocationKey();
  await issueCredentials(
    tester,
    irmaBinding,
    {
      'irma-demo.MijnOverheid.root.BSN': '12345',
    },
    revocationKeys: {'irma-demo.MijnOverheid.root': revocationKey},
  );
  await revokeCredential('irma-demo.MijnOverheid.root', revocationKey);

  // Start session
  await irmaBinding.repository.startTestSession('''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.MijnOverheid.root.BSN" ]
            ]
          ],
          "revocation": [ "irma-demo.MijnOverheid.root" ]
        }
      ''');

  await evaluateIntroduction(tester);

  // The disclosure permission overview screen should be visible.
  expect(find.text('Share my data'), findsOneWidget);
  expect(find.text('Share my data with demo.privacybydesign.foundation'), findsOneWidget);
  expect(find.text('Demo MijnOverheid.nl'), findsOneWidget);
  expect(find.text('12345'), findsOneWidget);
  expect(find.text('Revoked'), findsOneWidget);

  expect(
    tester
        .widget<YiviThemedButton>(
          find.ancestor(
            of: find.text('Share data'),
            matching: find.byType(YiviThemedButton),
          ),
        )
        .onPressed,
    isNull,
  );

  await issueCredentials(
    tester,
    irmaBinding,
    {
      'irma-demo.MijnOverheid.root.BSN': '12345',
    },
    revocationKeys: {'irma-demo.MijnOverheid.root': generateRevocationKey()},
  );

  expect(find.text('Revoked'), findsNothing);

  // Finish session.
  await tester.tapAndSettle(find.text('Share data'));
  await tester.tapAndSettle(find.text('Share'));

  await evaluateFeedback(tester);
  expect(find.byType(HomeScreen).hitTestable(), findsOneWidget);
}

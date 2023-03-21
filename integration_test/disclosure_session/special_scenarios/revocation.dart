import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choices_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/yivi_themed_button.dart';

import '../../helpers/helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';
import '../disclosure_helpers.dart';

Future<void> _evaluateDemoCredentialCard(
  WidgetTester tester,
  Finder revokedCardFinder, {
  required bool isRevoked,
}) =>
    evaluateCredentialCard(
      tester,
      revokedCardFinder,
      credentialName: 'Demo Root',
      issuerName: 'Demo MijnOverheid.nl',
      attributes: {'BSN': '12345'},
      isRevoked: isRevoked,
    );

Future<void> revocationTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Make sure a revoked credential is present
  final revocationKey = generateRevocationKey();
  await issueCredentials(
    tester,
    irmaBinding,
    {'irma-demo.MijnOverheid.root.BSN': '12345'},
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
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);
  expect(find.text('Share my data'), findsOneWidget);
  expect(find.text('Share my data with demo.privacybydesign.foundation'), findsOneWidget);

// Find all credential cards
  final cardsFinder = find.byType(IrmaCredentialCard);
  expect(cardsFinder, findsOneWidget);

  // Find the revoked credential card and evaluate it
  final demoCredentialCardFinder = cardsFinder.first;
  await _evaluateDemoCredentialCard(
    tester,
    demoCredentialCardFinder,
    isRevoked: true,
  );

  // Share data button should be disabled
  final shareDataButtonFinder = find.ancestor(
    of: find.text('Share data'),
    matching: find.byType(YiviThemedButton),
  );
  expect(
    tester.widget<YiviThemedButton>(shareDataButtonFinder).onPressed,
    isNull,
  );

  expect(find.text('Change choice'), findsNothing);

  // Now reobtain the card.
  await issueCredentials(
    tester,
    irmaBinding,
    {'irma-demo.MijnOverheid.root.BSN': '12345'},
    revocationKeys: {
      'irma-demo.MijnOverheid.root': generateRevocationKey(),
    },
  );

  // Revoked card should be visible here too.
  await _evaluateDemoCredentialCard(
    tester,
    demoCredentialCardFinder,
    isRevoked: false,
  );

  // Share data button should be enabled now
  expect(
    tester.widget<YiviThemedButton>(shareDataButtonFinder).onPressed,
    isNotNull,
  );

  await tester.tapAndSettle(find.text('Share data'));
  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}

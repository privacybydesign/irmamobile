import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/screens/data/credentials_details_screen.dart';
import 'package:irmamobile/src/screens/notifications/widgets/notification_bell.dart';
import 'package:irmamobile/src/screens/notifications/widgets/notification_card.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choices_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card_options_bottom_sheet.dart';
import 'package:irmamobile/src/widgets/irma_close_button.dart';
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

  // Close the add credential success screen
  await tester.tap(
    find.text('OK'),
  );

  await revokeCredential('irma-demo.MijnOverheid.root', revocationKey);
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
  expect(find.text('Share my data with is.demo.staging.yivi.app'), findsOneWidget);

  // Find all credential cards
  final cardsFinder = find.byType(IrmaCredentialCard);
  expect(cardsFinder, findsOneWidget);

  // Close the session
  await tester.tapAndSettle(find.byType(IrmaCloseButton));

  // Confirm the close dialog
  await tester.tapAndSettle(find.text('Yes'));

  // The NotificationBell should be findable in the app bar
  final notificationBellFinder = find.byType(NotificationBell);
  expect(notificationBellFinder, findsOneWidget);
  await tester.tapAndSettle(notificationBellFinder);

  // Now pull to refresh and expect a notification card
  await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
  await tester.pumpAndSettle();

  final notificationCardsFinder = find.byType(NotificationCard);
  expect(notificationCardsFinder, findsOneWidget);

  final notificationCardFinder = notificationCardsFinder.first;
  await evaluateNotificationCard(
    tester,
    notificationCardFinder,
    title: 'Data revoked',
    content: 'Demo MijnOverheid.nl has revoked this data: Demo Root',
    read: false,
  );

  // Tap the notification card to open the credential detail screen
  await tester.tapAndSettle(notificationCardFinder);

  // Expect the credential detail screen
  final credentialDetailScreenFinder = find.byType(CredentialsDetailsScreen);
  expect(credentialDetailScreenFinder, findsOneWidget);

  // Expect the actual credential card
  final credentialCardsFinder = find.byType(IrmaCredentialCard);
  expect(credentialCardsFinder, findsOneWidget);

  final credentialCardFinder = credentialCardsFinder.first;
  await evaluateCredentialCard(
    tester,
    credentialCardFinder,
    credentialName: 'Demo Root',
    issuerName: 'Demo MijnOverheid.nl',
    attributes: {'BSN': '12345'},
    isRevoked: true,
  );

  // Find the (more options) icon button in the credential card
  final iconButtonFinder = find.descendant(
    of: credentialCardFinder,
    matching: find.byType(IconButton),
  );
  expect(iconButtonFinder, findsOneWidget);
  await tester.tapAndSettle(iconButtonFinder);

  // Expect the options bottom sheet.
  expect(find.byType(IrmaCredentialCardOptionsBottomSheet), findsOneWidget);

  // Close the bottom sheet
  await tester.tapAndSettle(find.byType(IrmaCloseButton));

  // Start the disclosure session again
  await irmaBinding.repository.startTestSession('''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.MijnOverheid.root.BSN" ]
            ]
          ]
        }
      ''');

  await evaluateIntroduction(tester);
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);

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

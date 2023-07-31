import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/src/screens/data/credentials_detail_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';

import 'helpers/helpers.dart';
import 'helpers/issuance_helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('issuance', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    // Future<void> testIssueMunicipality(
    //   WidgetTester tester,
    //   Locale locale,
    // ) async {
    //   await pumpAndUnlockApp(
    //     tester,
    //     irmaBinding.repository,
    //     locale,
    //   );

    //   await issueMunicipalityPersonalData(
    //     tester,
    //     irmaBinding,
    //     locale: locale,
    //   );
    //   await tester.pumpAndSettle();

    //   final successScreenFinder = find.byType(IssuanceSuccessScreen);
    //   expect(successScreenFinder, findsOneWidget);

    //   // Expect the SuccessGraphic in the IssuanceSuccessScreen
    //   final successGraphicFinder = find.byType(SuccessGraphic);
    //   expect(
    //     find.descendant(
    //       of: successScreenFinder,
    //       matching: successGraphicFinder,
    //     ),
    //     findsOneWidget,
    //   );

    //   await tester.tapAndSettle(find.text('OK'));

    //   // Go to data tab
    //   await tester.tapAndSettle(find.byKey(const Key('nav_button_data')));

    //   // Expect CredentialTypeTile and tap it
    //   var categoryTileFinder = find.byKey(const Key('irma-demo.gemeente.personalData_tile')).hitTestable();
    //   await tester.scrollUntilVisible(categoryTileFinder, 75);
    //   await tester.tapAndSettle(categoryTileFinder);

    //   // Expect detail page
    //   expect(find.byType(CredentialsDetailScreen), findsOneWidget);

    //   // Expect to find a card
    //   final credentialCardFinder = find.byType(IrmaCredentialCard);
    //   expect(credentialCardFinder, findsOneWidget);
    // }

    // testWidgets(
    //   'issue-municipality-en',
    //   (tester) => testIssueMunicipality(tester, const Locale('en', 'EN')),
    // );

    // testWidgets(
    //   'issue-municipality-nl',
    //   (tester) => testIssueMunicipality(tester, const Locale('nl', 'NL')),
    // );

    // testWidgets('decline', (tester) async {
    //   await pumpAndUnlockApp(tester, irmaBinding.repository);

    //   // Start an issuance session for email address and decline the offer.
    //   await issueCredentials(
    //     tester,
    //     irmaBinding,
    //     {
    //       'irma-demo.sidn-pbdf.email.email': 'test@demo.com',
    //       'irma-demo.sidn-pbdf.email.domain': 'demo.com',
    //     },
    //     declineOffer: true,
    //   );

    //   // Go to data tab.
    //   await tester.tapAndSettle(find.byKey(const Key('nav_button_data')));

    //   // Verify that the email address has not been added.
    //   final emailTileFinder = find.byKey(const Key('irma-demo.sidn-pbdf.email_tile'));
    //   expect(emailTileFinder, findsNothing);

    //   // Verify that no activity has been added.
    //   await tester.tap(find.byKey(const Key('nav_button_activity')));
    //   await tester.pump(const Duration(seconds: 1));
    //   expect(find.text('There are no logged activities yet'), findsOneWidget);
    // });

    testWidgets('reissue', (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      await issueEmailAddress(tester, irmaBinding);

      // Press ok
      final okButtonFinder = find.text('OK');
      await tester.tapAndSettle(okButtonFinder);

      // Go to data tab.
      await tester.tapAndSettle(find.byKey(const Key('nav_button_data')));

      // Press the email tile.
      final emailTileFinder = find.byKey(const Key('irma-demo.sidn-pbdf.email_tile'));
      await tester.scrollUntilVisible(emailTileFinder, 75);
      await tester.tapAndSettle(emailTileFinder);

      // Expect the detail screen
      expect(find.byType(CredentialsDetailScreen), findsOneWidget);

      // Expect that it has one card.
      final credentialCardsFinder = find.byType(IrmaCredentialCard);
      expect(credentialCardsFinder, findsOneWidget);

      // Expect the card to have the correct content
      final credentialCardFinder = credentialCardsFinder.first;

      Future<void> evaluateIssuedEmailAddressCard() => evaluateCredentialCard(
            tester,
            credentialCardFinder,
            credentialName: 'Demo Email address',
            issuerName: 'Demo Privacy by Design Foundation via SIDN',
            attributes: {
              'Email address': 'test@example.com',
              'Email domain name': 'example.com',
            },
          );

      await evaluateIssuedEmailAddressCard();

      // Issue the same credential again.
      await issueEmailAddress(tester, irmaBinding);
      await tester.tapAndSettle(okButtonFinder);

      // Expect the detail screen with one card again
      await tester.tapAndSettle(emailTileFinder);
      expect(find.byType(CredentialsDetailScreen), findsOneWidget);
      expect(credentialCardsFinder, findsOneWidget);

      // Expect the card to have the correct content again
      await evaluateIssuedEmailAddressCard();
    });
  });
}

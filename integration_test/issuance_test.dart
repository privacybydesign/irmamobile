// We cannot test using null safety as long as there are widgets that are not migrated yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/src/screens/data/credentials_detail_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card_attribute_list.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card_header.dart';

import 'helpers.dart';
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

    Future<void> testIssueMunicipality(
      WidgetTester tester,
      Locale locale,
      List<String> expectedHeaderText,
      List<String> expectedAttributeText,
    ) async {
      await pumpAndUnlockApp(
        tester,
        irmaBinding.repository,
        locale,
      );

      await issueMunicipalityCards(
        tester,
        irmaBinding,
        locale: locale,
      );

      // Go to data tab
      await tester.tapAndSettle(find.byKey(const Key('nav_button_data')));

      // Expect CredentialTypeTile and tap it
      var categoryTileFinder = find.byKey(const Key('irma-demo.gemeente.personalData_tile')).hitTestable();
      await tester.scrollUntilVisible(categoryTileFinder, 75);
      await tester.tapAndSettle(categoryTileFinder);

      // Expect detail page
      expect(find.byType(CredentialsDetailScreen), findsOneWidget);

      // Expect to find a card
      final credentialCardFinder = find.byType(IrmaCredentialCard);
      expect(credentialCardFinder, findsOneWidget);

      // Expect correct text in the header
      final cardHeaderFinder =
          find.descendant(of: credentialCardFinder, matching: find.byType(IrmaCredentialCardHeader));
      final cardHeaderText = tester.getAllText(cardHeaderFinder);
      expect(cardHeaderText, expectedHeaderText);

      // Expect correct text in the attribute list
      final attributeListFinder =
          find.descendant(of: credentialCardFinder, matching: find.byType(IrmaCredentialCardAttributeList));
      final actualAttributeListText = tester.getAllText(attributeListFinder);
      final expectedAttributeListText = expectedAttributeText;
      expect(actualAttributeListText, expectedAttributeListText);
    }

    testWidgets(
        'issue-municipality-en',
        (tester) => testIssueMunicipality(
              tester,
              const Locale('en', 'EN'),
              [
                'Demo Personal data',
                'Demo Municipality',
              ],
              [
                'BSN',
                '999999990',
                'City of birth',
                'Amsterdam',
                'Country of birth',
                'Nederland',
                'Date of birth',
                '10-04-1965',
                'Assurance level',
                'Substantieel',
                'Family name',
                'Bruijn',
                'First names',
                'Willeke Liselotte',
                'Full name',
                'W.L. de Bruijn',
                'Gender',
                'V',
                'Initials',
                'W.L.',
                'Dutch nationality',
                'Yes',
                'Over 12',
                'Yes',
                'Over 16',
                'Yes',
                'Over 18',
                'Yes',
                'Over 21',
                'Yes',
                'Over 65',
                'No',
                'Prefix',
                'de',
                'Surname',
                'de Bruijn'
              ],
            ),
        timeout: const Timeout(
          Duration(minutes: 1, seconds: 30),
        ));

    testWidgets(
      'issue-municipality-nl',
      (tester) => testIssueMunicipality(
        tester,
        const Locale('nl', 'NL'),
        [
          'Demo Persoonsgegevens',
          'Demo Gemeente',
        ],
        [
          'BSN',
          '999999990',
          'Geboorteplaats',
          'Amsterdam',
          'Geboorteland',
          'Nederland',
          'Geboortedatum',
          '10-04-1965',
          'Betrouwbaarheidsniveau',
          'Substantieel',
          'Geslachtsnaam',
          'Bruijn',
          'Voornamen',
          'Willeke Liselotte',
          'Volledige naam',
          'W.L. de Bruijn',
          'Geslacht',
          'V',
          'Voorletters',
          'W.L.',
          'Nederlandse nationaliteit',
          'Ja',
          'Ouder dan 12',
          'Ja',
          'Ouder dan 16',
          'Ja',
          'Ouder dan 18',
          'Ja',
          'Ouder dan 21',
          'Ja',
          'Ouder dan 65',
          'Nee',
          'Voorvoegsel',
          'de',
          'Achternaam',
          'de Bruijn'
        ],
      ),
      timeout: const Timeout(
        Duration(minutes: 1, seconds: 30),
      ),
    );
  });
}

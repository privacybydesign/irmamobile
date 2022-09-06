// We cannot test using null safety as long as there are widgets that are not migrated yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/main.dart';

import 'helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  // TODO: repair tests and enable them again in test_all.dart.
  group('issuance', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() async => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets('add-cards-municipality', (tester) async {
      // Scenario 1 of issuance process
      // Initialize the app for integration tests
      await tester.pumpWidgetAndSettle(IrmaApp(repository: irmaBinding.repository));
      await unlock(tester);
      // start session
      await issueCardsMunicipality(tester, irmaBinding);
      // Check whether the cards are present in the wallet
      expect(tester.any(find.byKey(const Key('wallet_card_0'))), true);
      expect(tester.any(find.byKey(const Key('wallet_card_1'))), true);
      // Tap personal data card to open
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('wallet_card_1')), matching: find.byKey(const Key('card_title'))));
      // Checking Personal data card
      String string = tester
          .getAllText(find.descendant(
              of: find.byKey(const Key('wallet_card_1')), matching: find.byKey(const Key('card_title'))))
          .first;
      expect(string, 'Demo Personal data');

      // Checking Names and values
      // Checking full name
      await tester.scrollAndCheckText('wallet_card_1', 'attr_0_name', 'Full name');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_0_value', 'W.L. de Bruijn');

      // Checking initials
      await tester.scrollAndCheckText('wallet_card_1', 'attr_1_name', 'Initials');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_1_value', 'W.L.');

      // Checking first names
      await tester.scrollAndCheckText('wallet_card_1', 'attr_2_name', 'First names');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_2_value', 'Willeke Liselotte');

      // Checking prefix
      await tester.scrollAndCheckText('wallet_card_1', 'attr_3_name', 'Prefix');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_3_value', 'de');

      // Checking surname
      await tester.scrollAndCheckText('wallet_card_1', 'attr_4_name', 'Surname');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_4_value', 'de Bruijn');

      // Checking family name
      await tester.scrollAndCheckText('wallet_card_1', 'attr_5_name', 'Family name');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_5_value', 'Bruijn');

      // Checking gender
      await tester.scrollAndCheckText('wallet_card_1', 'attr_6_name', 'Gender');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_6_value', 'V');

      // Checking date of birth
      await tester.scrollAndCheckText('wallet_card_1', 'attr_7_name', 'Date of birth');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_7_value', '10-04-1965');

      // Checking age
      await tester.scrollAndCheckText('wallet_card_1', 'attr_8_name', 'Over 12');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_8_value', 'Yes');

      await tester.scrollAndCheckText('wallet_card_1', 'attr_9_name', 'Over 16');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_9_value', 'Yes');

      await tester.scrollAndCheckText('wallet_card_1', 'attr_10_name', 'Over 18');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_10_value', 'Yes');

      await tester.scrollAndCheckText('wallet_card_1', 'attr_11_name', 'Over 21');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_11_value', 'Yes');

      await tester.scrollAndCheckText('wallet_card_1', 'attr_12_name', 'Over 65');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_12_value', 'No');

      // Checking nationality
      await tester.scrollAndCheckText('wallet_card_1', 'attr_13_name', 'Dutch nationality');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_13_value', 'Yes');

      // Checking city of birth
      await tester.scrollAndCheckText('wallet_card_1', 'attr_14_name', 'City of birth');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_14_value', 'Amsterdam');

      // Checking country of birth
      await tester.scrollAndCheckText('wallet_card_1', 'attr_15_name', 'Country of birth');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_15_value', 'Nederland');

      // Checking BSN
      await tester.scrollAndCheckText('wallet_card_1', 'attr_16_name', 'BSN');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_16_value', '999999990');

      // Checking DigiD assurance level
      await tester.scrollAndCheckText('wallet_card_1', 'attr_17_name', 'Assurance level');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_17_value', 'Substantieel');

      // Tap personal data card to close
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('wallet_card_1')), matching: find.byKey(const Key('card_title'))));

      // Tap Demo address card to open
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('wallet_card_0')), matching: find.byKey(const Key('card_title'))));

      // Checking Demo address card
      string = tester
          .getAllText(find.descendant(
              of: find.byKey(const Key('wallet_card_0')), matching: find.byKey(const Key('card_title'))))
          .first;
      expect(string, 'Demo Address');
      // Checking Gemeente adresgegevens - Names and values

      // Checking Address
      await tester.scrollAndCheckText('wallet_card_0', 'attr_0_name', 'Street');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_0_value', 'Meander');

      // Checking Huisnummer
      await tester.scrollAndCheckText('wallet_card_0', 'attr_1_name', 'House number');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_1_value', '501');

      // Checking Postcode
      await tester.scrollAndCheckText('wallet_card_0', 'attr_2_name', 'Postal code');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_2_value', '1234AB');

      // Checking Gemeente
      await tester.scrollAndCheckText('wallet_card_0', 'attr_3_name', 'City');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_3_value', 'Arnhem');

      // Checking City
      await tester.scrollAndCheckText('wallet_card_0', 'attr_4_name', 'Municipality');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_4_value', 'Arnhem');
      // We have a large timeout because scrollAndCheckText takes too long.
    }, timeout: const Timeout(Duration(minutes: 1, seconds: 30)));

    testWidgets('add-cards-municipality-nl', (tester) async {
      // Scenario 2 yesno-display-hint
      // Initialize the app for integration tests
      await tester.pumpWidgetAndSettle(IrmaApp(
        forcedLocale: const Locale('nl', 'NL'),
        repository: irmaBinding.repository,
      ));
      await unlock(tester);
      // start session
      await issueCardsMunicipality(tester, irmaBinding);

      // Checking language Personal data card
      await tester.tapAndSettle(find.text('Demo Persoonsgegevens'));
      // Checking Names and values
      // Checking full name
      await tester.scrollAndCheckText('wallet_card_1', 'attr_0_name', 'Volledige naam');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_0_value', 'W.L. de Bruijn');

      // Checking initials
      await tester.scrollAndCheckText('wallet_card_1', 'attr_1_name', 'Voorletters');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_1_value', 'W.L.');

      // Checking first names
      await tester.scrollAndCheckText('wallet_card_1', 'attr_2_name', 'Voornamen');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_2_value', 'Willeke Liselotte');

      // Checking prefix
      await tester.scrollAndCheckText('wallet_card_1', 'attr_3_name', 'Voorvoegsel');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_3_value', 'de');

      // Checking surname
      await tester.scrollAndCheckText('wallet_card_1', 'attr_4_name', 'Achternaam');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_4_value', 'de Bruijn');

      // Checking family name
      await tester.scrollAndCheckText('wallet_card_1', 'attr_5_name', 'Geslachtsnaam');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_5_value', 'Bruijn');

      // Checking gender
      await tester.scrollAndCheckText('wallet_card_1', 'attr_6_name', 'Geslacht');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_6_value', 'V');

      // Checking date of birth
      await tester.scrollAndCheckText('wallet_card_1', 'attr_7_name', 'Geboortedatum');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_7_value', '10-04-1965');

      // Checking age
      await tester.scrollAndCheckText('wallet_card_1', 'attr_8_name', 'Ouder dan 12');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_8_value', 'Ja');

      await tester.scrollAndCheckText('wallet_card_1', 'attr_9_name', 'Ouder dan 16');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_9_value', 'Ja');

      await tester.scrollAndCheckText('wallet_card_1', 'attr_10_name', 'Ouder dan 18');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_10_value', 'Ja');

      await tester.scrollAndCheckText('wallet_card_1', 'attr_11_name', 'Ouder dan 21');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_11_value', 'Ja');

      await tester.scrollAndCheckText('wallet_card_1', 'attr_12_name', 'Ouder dan 65');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_12_value', 'Nee');

      // Checking nationality
      await tester.scrollAndCheckText('wallet_card_1', 'attr_13_name', 'Nederlandse nationaliteit');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_13_value', 'Ja');

      // Checking city of birth
      await tester.scrollAndCheckText('wallet_card_1', 'attr_14_name', 'Geboorteplaats');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_14_value', 'Amsterdam');

      // Checking country of birth
      await tester.scrollAndCheckText('wallet_card_1', 'attr_15_name', 'Geboorteland');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_15_value', 'Nederland');

      // Checking BSN
      await tester.scrollAndCheckText('wallet_card_1', 'attr_16_name', 'BSN');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_16_value', '999999990');

      // Checking DigiD assurance level
      await tester.scrollAndCheckText('wallet_card_1', 'attr_17_name', 'Betrouwbaarheidsniveau');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_17_value', 'Substantieel');

      // Close the Personal Data card
      await tester.tapAndSettle(find.text('Demo Persoonsgegevens'));

      // Checking language Demo address card
      await tester.tapAndSettle(find.text('Demo Adres'));

      // Checking Gemeente adresgegevens - Names and values
      // Checking Address
      await tester.scrollAndCheckText('wallet_card_0', 'attr_0_name', 'Straat');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_0_value', 'Meander');

      // Checking Huisnummer
      await tester.scrollAndCheckText('wallet_card_0', 'attr_1_name', 'Huisnummer');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_1_value', '501');

      // Checking Postcode
      await tester.scrollAndCheckText('wallet_card_0', 'attr_2_name', 'Postcode');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_2_value', '1234AB');

      // Checking Gemeente
      await tester.scrollAndCheckText('wallet_card_0', 'attr_4_name', 'Gemeente');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_4_value', 'Arnhem');

      // Checking City
      await tester.scrollAndCheckText('wallet_card_0', 'attr_3_name', 'Woonplaats');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_3_value', 'Arnhem');
      // We have a large timeout because scrollAndCheckText takes too long.
    }, timeout: const Timeout(Duration(minutes: 1, seconds: 30)));
  });
}

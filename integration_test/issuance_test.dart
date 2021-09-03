import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/main.dart';
import 'package:irmamobile/src/data/irma_test_repository.dart';

import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('irma-issuance', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    IrmaTestRepository testRepo;
    setUpAll(() async => testRepo = await IrmaTestRepository.ensureInitialized());
    setUp(() => testRepo.init());
    tearDown(() => testRepo.clean());

    testWidgets('tc1', (tester) async {
      // Scenario 1 of issuance process
      // Initialize the app for integration tests
      await tester.pumpWidgetAndSettle(IrmaApp());
      // Tap through enrollment info screens
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('enrollment_p1')), matching: find.byKey(const Key('next'))));
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('enrollment_p2')), matching: find.byKey(const Key('next'))));
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('enrollment_p3')), matching: find.byKey(const Key('next'))));
      // Enter pin
      await tester.enterTextAtFocusedAndSettle('12345');
      // Confirm pin
      await tester.enterTextAtFocusedAndSettle('12345');
      // Skip email providing
      await tester.tapAndSettle(find.byKey(const Key('enrollment_skip_email')));
      await tester.tap(find.byKey(const Key('enrollment_skip_confirm')));
      // Wait until wallet displayed
      await tester.waitFor(find.byKey(const Key('wallet_present')));

      // Start session
      await testRepo.inner.startTestSession('''
        {
          "@context": "https://irma.app/ld/request/issuance/v2",
          "credentials": [
            {
              "credential": "irma-demo.gemeente.personalData",
              "attributes": {
                "initials": "W.L.",
                "firstnames": "Willeke Liselotte",
                "prefix": "de",
                "familyname": "Bruijn",
                "fullname": "W.L. de Bruijn",
                "gender": "V",
                "nationality": "Ja",
                "surname": "de Bruijn",
                "dateofbirth": "10-04-1965",
                "cityofbirth": "Amsterdam",
                "countryofbirth": "Nederland",
                "over12": "Yes",
                "over16": "Yes",
                "over18": "Yes",
                "over21": "Yes",
                "over65": "No",
                "bsn": "999999990",
                "digidlevel": "Substantieel"
              }
            },
            {
              "credential": "irma-demo.gemeente.address",
              "attributes": {
                "street":"Meander","houseNumber":"501","zipcode":"1234AB","municipality":"Arnhem","city":"Arnhem"
              }
            }
          ]
        }
      ''');
      // Accept issued credential
      await tester.waitFor(find.byKey(const Key('issuance_accept')));
      await tester.tap(
          find.descendant(of: find.byKey(const Key('issuance_accept')), matching: find.byKey(const Key('primary'))));
      // Wait until done
      await tester.waitFor(find.byKey(const Key('wallet_present')));

      // Check whether the cards are present in the wallet
      expect(tester.any(find.byKey(const Key('wallet_card_0'))), true);
      expect(tester.any(find.byKey(const Key('wallet_card_1'))), true);
      print('wait 5 seconds');
      await tester.pumpAndSettle(const Duration(seconds: 5));
      print('Tap personal data card to open');
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('wallet_card_0')), matching: find.byKey(const Key('card_title'))));

      print('Checking Personal data card');
      String string = tester.getText(
          find.descendant(of: find.byKey(const Key('wallet_card_0')), matching: find.byKey(const Key('card_title'))));

      expect(string, 'Demo Personal data');

      print('Checking Names and values');

      print('checking initials');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_0_name', 'Initials');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_0_value', 'W.L.');

      print('checking First names');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_1_name', 'First names');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_1_value', 'Willeke Liselotte');

      print('checking Prefix');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_2_name', 'Prefix');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_2_value', 'de');

      print('checking Family name');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_3_name', 'Family name');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_3_value', 'Bruijn');

      print('checking Full name');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_4_name', 'Full name');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_4_value', 'W.L. de Bruijn');

      print('checking Gender');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_5_name', 'Gender');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_5_value', 'V');

      print('checking nationality');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_6_name', 'Dutch nationality');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_6_value', 'Ja');

      print('checking Surname');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_7_name', 'Surname');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_7_value', 'de Bruijn');

      print('checking Date of birth');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_8_name', 'Date of birth');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_8_value', '10-04-1965');

      print('checking City of birth');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_9_name', 'City of birth');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_9_value', 'Amsterdam');

      print('checking Country of birth');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_10_name', 'Country of birth');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_10_value', 'Nederland');

      print('checking Age');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_11_name', 'Over 12');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_11_value', 'Yes');

      await tester.scrollAndCheckText('wallet_card_0', 'attr_12_name', 'Over 16');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_12_value', 'Yes');

      await tester.scrollAndCheckText('wallet_card_0', 'attr_13_name', 'Over 18');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_13_value', 'Yes');

      await tester.scrollAndCheckText('wallet_card_0', 'attr_14_name', 'Over 21');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_14_value', 'Yes');

      await tester.scrollAndCheckText('wallet_card_0', 'attr_15_name', 'Over 65');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_15_value', 'No');

      print('Checking BSN');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_16_name', 'BSN');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_16_value', '999999990');

      print('checking DigiD assurance level');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_17_name', 'DigiD assurance level');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_17_value', 'Substantieel');

      print('Tap personal data card to close');
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('wallet_card_0')), matching: find.byKey(const Key('card_title'))));

      print('Tap Demo address card to open');
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('wallet_card_1')), matching: find.byKey(const Key('card_title'))));

      print('Checking Demo address card');

      string = tester.getText(
          find.descendant(of: find.byKey(const Key('wallet_card_1')), matching: find.byKey(const Key('card_title'))));
      expect(string, 'Demo Address');
      print('Checking Gemeente adresgegevens - Names and values');

      print('Checking Address');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_0_name', 'Street');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_0_value', 'Meander');

      print('Checking Huisnummer');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_1_name', 'House number');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_1_value', '501');

      print('Checking Postcode');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_2_name', 'Zip code');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_2_value', '1234AB');

      print('Checking Gemeente');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_3_name', 'Municipality');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_3_value', 'Arnhem');

      print('Checking City');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_4_name', 'City');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_4_value', 'Arnhem');
    }, timeout: const Timeout(Duration(minutes: 4)));
  });
}

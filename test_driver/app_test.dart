import 'dart:async';
import 'dart:convert';
import 'dart:io';

// Imports the Flutter Driver API.
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('IrmaMobile', () {
    FlutterDriver driver;
    StreamSubscription streamSubscription;

    setUpAll(() async {
      // Connect to a running Flutter application instance.
      driver = await FlutterDriver.connect();
      streamSubscription = driver.serviceClient.onIsolateRunnable.asBroadcastStream().listen((isolateRef) {
        // This is a workaround for https://github.com/flutter/flutter/issues/24703.
        isolateRef.resume();
      });

      print('Forwarding necessary ports...');
      await Process.run('adb', ['reverse', 'tcp:8080', 'tcp:8080']);
      await Process.run('adb', ['reverse', 'tcp:8088', 'tcp:8088']);
    });

    tearDownAll(() async {
      streamSubscription?.cancel();
      if (driver != null) await driver.close();
    });

    Future<void> _startIrmaSession(String request) async {
      final requestH = await HttpClient().postUrl(Uri.parse('http://localhost:8088/session'));
      requestH.headers.set('Content-Type', 'application/json');
      requestH.write(request);
      final response = await requestH.close();
      final sessionData = await response.transform(utf8.decoder).first;
      final data = jsonDecode(sessionData) as Map<String, dynamic>;
      await driver.requestData(jsonEncode(data["sessionPtr"]));
    }

    test('main', () async {
      // Wait for initialization
      await driver.waitFor(find.byValueKey('enrollment_p1'));

      // Initialize the app for integration tests (enable developer mode, etc.)
      await driver.requestData('initialize');

      // Tap through enrollment info screens
      await driver.tap(find.descendant(of: find.byValueKey('enrollment_p1'), matching: find.byValueKey('next')));
      await driver.tap(find.descendant(of: find.byValueKey('enrollment_p2'), matching: find.byValueKey('next')));
      await driver.tap(find.descendant(of: find.byValueKey('enrollment_p3'), matching: find.byValueKey('next')));

      // Enter pin
      await driver.waitFor(find.byValueKey('enrollment_choose_pin'));
      await driver.enterText('12345');

      // Confirm pin
      await driver.waitFor(find.byValueKey('enrollment_confirm_pin'));
      await driver.enterText('12345');

      // Skip email providing
      await driver.tap(find.byValueKey('enrollment_skip_email'));
      await driver.tap(find.byValueKey('enrollment_skip_confirm'));

      // Wait until wallet displayed
      await driver.waitFor(find.byValueKey('wallet_present'));

      // Start session
      await _startIrmaSession("""{
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
      }""");

      // Accept issued credential
      await driver.tap(find.descendant(of: find.byValueKey('issuance_accept'), matching: find.byValueKey('primary')));

      // Wait until done
      await driver.waitFor(find.byValueKey('wallet_present'));

      // Check whether the cards are present in the wallet
      await driver.waitFor(find.byValueKey('wallet_card_0'));
      await driver.waitFor(find.byValueKey('wallet_card_1'));
      print("wait 5 seconds");
      await Future.delayed(Duration(seconds: 5));
      print("Tap personal data card to open");
      await driver.tap(find.descendant(of: find.byValueKey('wallet_card_1'), matching: find.byValueKey('card_title')));
      print("wait 2 seconds");
      await Future.delayed(Duration(seconds: 2));
      print("Checking Personal data card");
      String string = await driver.getText(find.descendant(of: find.byValueKey('wallet_card_1'), matching: find.byValueKey('card_title')));

      expect(string, 'Demo Personal data');



      print("Checking Names and values");

      print("checking initials");
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_0_name', 'Initials');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_0_value', 'W.L.');

      print("checking First names");
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_1_name', 'First names');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_1_value', 'Willeke Liselotte');

      print("checking Prefix");
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_2_name', 'Prefix');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_2_value', 'de');

      print("checking Family name");
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_3_name', 'Family name');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_3_value', 'Bruijn');


      print("checking Full name");
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_4_name', 'Full name');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_4_value', 'W.L. de Bruijn');

      print("checking Gender");
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_5_name', 'Gender');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_5_value', 'V');



      print("checking nationality");
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_6_name', 'Dutch nationality');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_6_value', 'Ja');

      print("checking Surname");
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_7_name', 'Surname');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_7_value', 'de Bruijn');

      print("checking Date of birth");
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_8_name', 'Date of birth');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_8_value', '10-04-1965');


      print("checking City of birth");
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_9_name', 'City of birth');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_9_value', 'Amsterdam');

      print("checking Country of birth");
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_10_name', 'Country of birth');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_10_value', 'Nederland');

      print("checking Age");
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_11_name', 'Over 12');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_11_value', 'Yes');

      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_12_name', 'Over 16');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_12_value', 'Yes');


      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_13_name', 'Over 18');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_13_value', 'Yes');

      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_14_name', 'Over 21');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_14_value', 'Yes');

      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_15_name', 'Over 65');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_15_value', 'No');

      print("Checking BSN");
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_16_name', 'BSN');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_16_value', '999999990');

      print("checking DigiD assurance level");
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_17_name', 'DigiD assurance level');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_17_value', 'Substantieel');

      print("Tap personal data card to close");
      await driver.tap(find.descendant(of: find.byValueKey('wallet_card_1'), matching: find.byValueKey('card_title')));

      await Future.delayed(Duration(seconds: 2));
      print("Tap Demo address card to open");
      await driver.tap(find.descendant(of: find.byValueKey('wallet_card_0'), matching: find.byValueKey('card_title')));
      await Future.delayed(Duration(seconds: 2));

      print("Checking Demo address card");

      string = await driver.getText(find.descendant(of: find.byValueKey('wallet_card_0'), matching: find.byValueKey('card_title')));
      expect(string, 'Demo Address');
      print("Checking Gemeente adresgegevens - Names and values");

      print("Checking Address");
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_0_name', 'Street');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_0_value', 'Meander');

      print("Checking Huisnummer");
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_1_name', 'House number');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_1_value', '501');

      print("Checking Postcode");
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_2_name', 'Zip code');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_2_value', '1234AB');

      print("Checking Gemeente");
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_3_name', 'Municipality');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_3_value', 'Arnhem');

      print("Checking City");
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_4_name', 'City');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_4_value', 'Arnhem');

      await Future.delayed(Duration(seconds: 520));
    }, timeout: const Timeout(Duration(minutes: 4)));
  });

}

Future<void> scrollAndCheckText(FlutterDriver driver, String parentKey, String textKey, String textValue) async {
  final widget = find.descendant(of: find.byValueKey(parentKey), matching: find.byValueKey(textKey));
  await driver.scrollIntoView(widget);
  final string = await driver.getText(widget);
  expect(string, textValue);
}

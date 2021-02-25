import 'dart:async';
import 'dart:convert';
import 'dart:io';

// Imports the Flutter Driver API.
import 'package:flutter_driver/flutter_driver.dart';
import 'package:screenshots/screenshots.dart';
import 'package:test/test.dart';

// TODO: Improve ability to run this script, maybe integrate with test_driver/main.dart.
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

      // Forward neccessary ports
      await Process.run('adb', ['reverse', 'tcp:8080', 'tcp:8080']);
      await Process.run('adb', ['reverse', 'tcp:8088', 'tcp:8088']);
    });

    tearDownAll(() async {
      if (driver != null) await driver.close();
      if (streamSubscription != null) streamSubscription.cancel();
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

    test('screenshots', () async {
      final config = Config();

      // Wait for initialization
      await driver.waitUntilFirstFrameRasterized();
      await driver.waitFor(find.byValueKey('next_enrollment_p1'));

      // Enable developer mode
      await driver.requestData("");

      // Tap through enrollment info screens
      await driver.tap(find.byValueKey('next_enrollment_p1'));
      await driver.tap(find.byValueKey('next_enrollment_p2'));
      await screenshot(driver, config, 'enrollment');
      await driver.tap(find.byValueKey('next_enrollment_p3'));

      // Enter pin
      await driver.waitFor(find.byValueKey('enrollment_choose_pin'));
      await driver.enterText('12345');

      // Confirm pin
      await driver.waitFor(find.byValueKey('enrollment_confirm_pin'));
      await driver.enterText('12345');

      // Skip email providing
      await driver.tap(find.byValueKey('enrollment_skip_email'));
      await driver.tap(find.byValueKey('skip_confirm'));

      // Wait until wallet displayed
      await driver.waitFor(find.byValueKey('wallet_present'));

      // Start session
      await _startIrmaSession("""{
        "@context": "https://irma.app/ld/request/issuance/v2",
        "credentials": [
          {
            "credential": "test.gemeente.personalData",
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
            "credential": "test.gemeente.address",
            "attributes": {
              "street":"","houseNumber":"","zipcode":"1234AB","municipality":"","city":""
            }
          }
        ]
      }""");

      // Accept issued credential
      await driver.tap(find.byValueKey('issuance_accept_yes'));

      // Wait until done
      await driver.waitFor(find.byValueKey('wallet_present'));

      // And wait until new-credential animation is done (with margin)
      await Future.delayed(const Duration(seconds: 10));

      // Show off wallet with personalData card visible
      await driver.tap(find.byValueKey('walletcard_test.gemeente.personalData'));

      await screenshot(driver, config, 'wallet');

      // Show off pin screen
      await driver.tap(find.byValueKey('wallet_lock'));

      await screenshot(driver, config, 'lockscreen');

      await driver.enterText('12345');

      // Open store
      await driver.tap(find.byValueKey('wallet_menu'));
      await driver.tap(find.byValueKey('menu_add_cards'));

      await screenshot(driver, config, 'credential_store');

      // open personaldata store
      await driver.tap(find.byValueKey('add_card_test.gemeente.personalData'));
      await driver.tap(find.byValueKey('purpose_question'));

      await screenshot(driver, config, 'credential_store_personalData');

      // show disclosure screen
      await _startIrmaSession("""{
        "@context": "https://irma.app/ld/request/disclosure/v2",
        "disclose": [
          [
            [
              "test.gemeente.personalData.firstnames",
              "test.gemeente.address.zipcode"
            ],
            [
              "test.sidn-pbdf.email.email"
            ]
          ]
        ]
      }
      """);

      await driver.waitFor(find.byValueKey('disclosure_yes'));

      // dismiss choice prompt
      await driver.tap(find.byValueKey('choose_ok'));

      await screenshot(driver, config, 'disclosure_permission');

      // finish session
      await driver.tap(find.byValueKey('disclosure_yes'));

      await driver.tap(find.byValueKey('feedback_dismiss'));

      // go to history
      await driver.tap(find.byValueKey('wallet_menu'));

      await driver.tap(find.byValueKey('menu_history'));

      await screenshot(driver, config, 'history_overview');

      // open history details
      await driver.tap(find.byValueKey('logentry_1'));

      await screenshot(driver, config, 'history_details');
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}

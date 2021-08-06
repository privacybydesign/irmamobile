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

    // Reset the app after each test.
    tearDown(() => driver.requestData('reset'));

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
      await driver.requestData(jsonEncode(data['sessionPtr']));
    }

    test('irma-screens-tc1', () async {
      // Scenario 1 of IRMA app screens
      // Wait for initialization
      await driver.waitFor(find.byValueKey('enrollment_p1'));
      // Initialize the app for integration tests (enable developer mode, etc.)
      await driver.requestData('initialize');

      // Check first screen
      //Check Next button is available
      await driver.waitFor(find.descendant(of: find.byValueKey('enrollment_p1'), matching: find.byValueKey('next')));
      print("Check intro heading");
      String string = await getTextFirstMatch(driver, find.byValueKey('intro_heading'));
      expect(string, 'IRMA is your identity on your mobile');
      print("Check intro text");
      string = await getTextFirstMatch(driver, find.byValueKey('intro_body'));
      expect(string, 'Your official name, date of birth, address, and more. All securely stored in your IRMA app.');

      // Tap through enrollment info screens
      await driver.tap(find.descendant(of: find.byValueKey('enrollment_p1'), matching: find.byValueKey('next')));

      // Check second screen
      // Check Next button is available
      await driver.waitFor(find.descendant(of: find.byValueKey('enrollment_p2'), matching: find.byValueKey('next')));
      print("Check intro heading");
      string = await getTextFirstMatch(driver, find.byValueKey('intro_heading'));
      expect(string, 'Make yourself known with IRMA');
      print("Check intro text");
      string = await getTextFirstMatch(driver, find.byValueKey('intro_body'));
      expect(string, "Easy, secure, and fast. It's all in your hands.");

      await driver.tap(find.descendant(of: find.byValueKey('enrollment_p2'), matching: find.byValueKey('next')));

      // Check third screen
      // Check Next button is available
      await driver.waitFor(find.descendant(of: find.byValueKey('enrollment_p3'), matching: find.byValueKey('next')));
      print("Check intro heading");
      string = await getTextFirstMatch(driver, find.byValueKey('intro_heading'));
      expect(string, 'IRMA provides certainty, to you and to others');
      print("Check intro text");
      string = await getTextFirstMatch(driver, find.byValueKey('intro_body'));
      expect(string, "Your data are stored solely within the IRMA app. Only you have access.");
      string = await getTextFirstMatch(driver, find.byValueKey('intro_body_link'));

      expect(string, "Please read the privacy rules");

      await driver.tap(find.descendant(of: find.byValueKey('enrollment_p3'), matching: find.byValueKey('next')));

      // Choose new pin screen
      await driver.waitFor(find.byValueKey('enrollment_choose_pin'));
    }, timeout: const Timeout(Duration(minutes: 4)));

    test('irma-screens-tc2', () async {
      // Scenario 2 of IRMA app screens
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
      // Open menu
      await driver.tap(find.byValueKey('open_menu_icon'));
      await Future.delayed(const Duration(seconds: 1));
      // Logout
      await driver.tap(find.byValueKey('menu_logout'));
      await Future.delayed(const Duration(seconds: 1));
      // login window is displayed
      await driver.waitFor(find.byValueKey('pin_screen'));
      // Check screen title
      String string = await getTextFirstMatch(driver, find.byValueKey('pinscreen_app_bar'));
      expect(string, 'Login');

      string = await driver.getText(
          find.descendant(of: find.byValueKey('pin_screen'), matching: find.byType('Text'), firstMatchOnly: true));
      expect(string, 'Enter your PIN');
      await driver.waitFor(find.byValueKey('pin_field_key'));
      string = await getTextFirstMatch(driver, find.byValueKey('irma_link'));
      expect(string, 'PIN forgotten');

      await driver.tap(find.byValueKey('irma_link'));
      await Future.delayed(const Duration(seconds: 1));

      await driver.waitFor(find.byValueKey('reset_pin_screen'));

      string = await getTextFirstMatch(driver, find.byValueKey('reset_pin_screen'));

      String screenText =
          '''Lost your PIN? We\'re sorry but the IRMA organisation does not keep record of your PIN. If you wish to continue using IRMA, you will have to enter a new PIN and reload all data.''';

      expect(string, screenText);

      // Check buttons Back and Reset
      await driver
          .waitFor(find.descendant(of: find.byValueKey('reset_pin_buttons'), matching: find.byValueKey('primary')));
      await driver
          .waitFor(find.descendant(of: find.byValueKey('reset_pin_buttons'), matching: find.byValueKey('secondary')));
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('irma-screens-tc4', () async {
      // Scenario 4 of IRMA app screens
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
      // Check wallet text
      String string = await getTextFirstMatch(driver, find.byValueKey('wallet_screen'));
      expect(string, 'Your data securely on your mobile');
      // Check button Add more data
      await driver.waitFor(find.byValueKey('add_cards_button'));

      // Wallet should not contain any cards
      await driver.waitForAbsent(find.byValueKey('wallet_card_0'));
    }, timeout: const Timeout(Duration(minutes: 4)));

    test('irma-screens-tc5', () async {
      // Scenario 5 of IRMA app screens: Help screen
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

      await driver.tap(find.byValueKey('wallet_button_help'));

      // Check screen title
      String string = await getTextFirstMatch(driver, find.byValueKey('irma_app_bar'));
      expect(string, 'Help');
      // Check screen header
      string = await getTextFirstMatch(driver, find.byValueKey('help_screen_heading'));
      expect(string, 'Manual');
      // Check box content
      string = await getTextFirstMatch(driver, find.byValueKey('help_screen_content'));
      expect(string, 'How to use IRMA? See the explanations below.');
      // Check button "Back to IRMA cards"
      await driver.waitFor(find.byValueKey('back_to_wallet_button'));
    }, timeout: const Timeout(Duration(minutes: 4)));

    test('irma-login-tc1', () async {
      // Scenario 1 of login process
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
      // Open menu
      await driver.tap(find.byValueKey('open_menu_icon'));
      await Future.delayed(const Duration(seconds: 1));
      // Logout
      await driver.tap(find.byValueKey('menu_logout'));
      await Future.delayed(const Duration(seconds: 1));
      // login using wrong pin
      await driver.waitFor(find.byValueKey('pin_screen'));
      await driver.enterText('54321');
      // Check error dialog
      await driver.waitFor(find.byValueKey('irma_dialog'));
      await Future.delayed(const Duration(seconds: 2));
      // Check "Wrong PIN" dialog title text
      print('check dialog title');
      String string = await driver.getText(find.byValueKey('irma_dialog_title'));
      expect(string, 'PIN incorrect');
      // Check dialog text
      string = await driver.getText(find.byValueKey('irma_dialog_content'));
      expect(string,
          'This PIN is not correct. You have 2 attempts left before your IRMA app will be blocked temporarily.');

      await driver.tap(find.descendant(
        of: find.byValueKey('irma_dialog'),
        matching: find.byType('IrmaButton'),
        firstMatchOnly: true,
      ));
      // Wait until wallet displayed: Successful login
      await driver.waitFor(find.byValueKey('wallet_present'));
    }, timeout: const Timeout(Duration(minutes: 4)));

    test('irma-login-tc2', () async {
      // Scenario 2 of login process: User is blocked after 3 failed attempts.
      await driver.waitFor(find.byValueKey('enrollment_p1'));
      // Initialize the app for integration tests (enable developer mode, etc.)
      await driver.requestData('initialize');
      // Tap through enrollment info screens
      await driver.tap(find.descendant(of: find.byValueKey('enrollment_p1'), matching: find.byValueKey('next')));
      await driver.tap(find.descendant(of: find.byValueKey('enrollment_p2'), matching: find.byValueKey('next')));
      await driver.tap(find.descendant(of: find.byValueKey('enrollment_p3'), matching: find.byValueKey('next')));
      // Enter pin
      await driver.tap(find.byValueKey('pin_field_key'));
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
      // Open menu
      await driver.tap(find.byValueKey('open_menu_icon'));
      await Future.delayed(const Duration(seconds: 1));
      // Logout
      await driver.tap(find.byValueKey('menu_logout'));
      await Future.delayed(const Duration(seconds: 1));
      // login using wrong pin
      await driver.waitFor(find.byValueKey('pin_screen'));
      await driver.enterText('54321');
      // Check error dialog
      await driver.waitFor(find.byValueKey('irma_dialog'));
      await Future.delayed(const Duration(seconds: 1));
      // Check "Wrong PIN" dialog title text
      String string = await driver.getText(find.byValueKey('irma_dialog_title'));
      expect(string, 'PIN incorrect');
      // Check dialog text
      string = await driver.getText(find.byValueKey('irma_dialog_content'));
      expect(string,
          'This PIN is not correct. You have 2 attempts left before your IRMA app will be blocked temporarily.');
      await driver.tap(find.descendant(
        of: find.byValueKey('irma_dialog'),
        matching: find.byType('IrmaButton'),
        firstMatchOnly: true,
      ));
      // login using wrong pin
      await driver.waitFor(find.byValueKey('pin_screen'));
      await driver.enterText('54321');
      // Check error dialog
      await driver.waitFor(find.byValueKey('irma_dialog'));
      await Future.delayed(const Duration(seconds: 1));
      // Check "Wrong PIN" dialog title text
      string = await driver.getText(find.byValueKey('irma_dialog_title'));
      expect(string, 'PIN incorrect');
      // Check dialog text
      string = await driver.getText(find.byValueKey('irma_dialog_content'));
      expect(
          string, 'This PIN is not correct. You have 1 attempt left before your IRMA app will be blocked temporarily.');
      await driver.tap(find.descendant(
        of: find.byValueKey('irma_dialog'),
        matching: find.byType('IrmaButton'),
        firstMatchOnly: true,
      ));
      // login using wrong pin
      await driver.waitFor(find.byValueKey('pin_screen'));
      await driver.enterText('54321');
      // Check error dialog
      await driver.waitFor(find.byValueKey('irma_dialog'));
      await Future.delayed(const Duration(seconds: 1));
      // Check "Wrong PIN" dialog title text
      string = await driver.getText(find.byValueKey('irma_dialog_title'));
      expect(string, 'Account blocked');
      // Check dialog text
      string = await driver.getText(find.byValueKey('irma_dialog_content'));

      expect(string, 'Your account has been blocked for 1 minute. Please try again later.');
      await driver.tap(find.descendant(
        of: find.byValueKey('irma_dialog'),
        matching: find.byType('IrmaButton'),
        firstMatchOnly: true,
      ));
      // Wait 65 seconds and try again using the correct pin
      print('Wait 65 seconds for account to get unlocked...');
      await Future.delayed(const Duration(seconds: 65));
      // login using correct pin
      await driver.waitFor(find.byValueKey('pin_screen'));
      // Click pin field to open keyboard
      await driver.tap(find.byValueKey('pin_field_key'));
      await Future.delayed(const Duration(seconds: 1));
      await driver.enterText('54321');
      // Wait until wallet displayed: Successful login
      await driver.waitFor(find.byValueKey('wallet_present'));
    }, timeout: const Timeout(Duration(minutes: 10)));

    test('irma-enroll-tc1', () async {
      // Scenario 1 of enrollment process
      // Wait for initialization
      await driver.waitFor(find.byValueKey('enrollment_p1'));
      // Initialize the app for integration tests (enable developer mode, etc.)
      await driver.requestData('initialize');

      // Tap through enrollment info screens
      await driver.tap(find.descendant(of: find.byValueKey('enrollment_p1'), matching: find.byValueKey('next')));
      await driver.tap(find.descendant(of: find.byValueKey('enrollment_p2'), matching: find.byValueKey('next')));
      await driver.tap(find.descendant(of: find.byValueKey('enrollment_p3'), matching: find.byValueKey('next')));

      // Choose new pin screen
      await driver.waitFor(find.byValueKey('enrollment_choose_pin'));
      // Enter Pin
      await driver.enterText('12345');
      // Enter wrong pin
      await driver.waitFor(find.byValueKey('enrollment_confirm_pin'));
      await driver.enterText('67890');

      await driver.waitFor(find.byValueKey('irma_dialog'));

      // Check "Wrong PIN" dialog title text
      String string = await driver.getText(find.byValueKey('irma_dialog_title'));
      expect(string, 'PIN incorrect');
      // Check dialog text
      string = await driver.getText(find.byValueKey('irma_dialog_content'));
      expect(string, 'PINs do not match. Choose a new PIN.');

      await driver.tap(find.descendant(
          of: find.byValueKey('irma_dialog'), matching: find.byType('IrmaButton'), firstMatchOnly: true));

      // Choose new pin screen
      await driver.waitFor(find.byValueKey('enrollment_choose_pin'));
      // Enter Pin
      await driver.enterText('12345');
      // Enter wrong pin
      await driver.waitFor(find.byValueKey('enrollment_confirm_pin'));
      await driver.enterText('12345');

      // Enter email address
      await driver.waitFor(find.byValueKey('enrollment_provide_email'));

      // Check error message is not displayed
      await driver.waitForAbsent(find.descendant(
          of: find.byValueKey('enrollment_provide_email_textfield'),
          matching: find.text('This is not a valid email address')));

      await driver.enterText('Wrong_syntax');
      await driver.tap(find.byValueKey('enrollment_email_next'));

      // Check error message
      await driver.waitFor(find.descendant(
          of: find.byValueKey('enrollment_provide_email_textfield'),
          matching: find.text('This is not a valid email address')));

      // Check textfield is still present
      await driver.waitFor(find.descendant(
          of: find.byValueKey('enrollment_provide_email'), matching: find.byType('TextField'), firstMatchOnly: true));

      await driver.enterText('testing_irma_app@example.com');
      await driver.tap(find.byValueKey('enrollment_email_next'));

      // Wait for Email confirmation screen
      await driver.waitFor(find.byValueKey('email_sent_screen'));
      print('check screen title');
      // Check screen title
      string = await getTextFirstMatch(driver, find.byValueKey('irma_app_bar'));
      expect(string, 'Secure your IRMA app');

      // Check text
      string = await driver.getText(find.descendant(
          of: find.byValueKey('email_sent_screen'), matching: find.byType('Text'), firstMatchOnly: true));
      expect(string, 'Confirm your email address');

      // Click continue
      await driver.tap(
          find.descendant(of: find.byValueKey('email_sent_screen_continue'), matching: find.byValueKey('primary')));

      // Wait until wallet displayed
      await driver.waitFor(find.byValueKey('wallet_present'));
      // No cards should be available in the wallet
      await driver.waitForAbsent(find.byValueKey('wallet_card_0'));
    }, timeout: const Timeout(Duration(minutes: 4)));

    test('irma-enroll-tc2', () async {
      // Scenario 2 of enrollment process
      // Wait for initialization
      await driver.waitFor(find.byValueKey('enrollment_p1'));

      // Initialize the app for integration tests (enable developer mode, etc.)
      await driver.requestData('initialize');

      // Tap through enrollment info screens
      await driver.tap(find.descendant(of: find.byValueKey('enrollment_p1'), matching: find.byValueKey('next')));
      await driver.tap(find.descendant(of: find.byValueKey('enrollment_p2'), matching: find.byValueKey('next')));
      await driver.tap(find.descendant(of: find.byValueKey('enrollment_p3'), matching: find.byValueKey('next')));

      // Choose new pin screen
      await driver.waitFor(find.byValueKey('enrollment_choose_pin'));

      // Check screen title
      String string = await getTextFirstMatch(driver, find.byValueKey('irma_app_bar'));
      expect(string, 'Secure your IRMA app');

      // Check text
      string = await driver.getText(find.descendant(
          of: find.byValueKey('enrollment_choose_pin'), matching: find.byType('Text'), firstMatchOnly: true));
      expect(string, 'Choose a 5-digit PIN');

      // Enter Pin
      print('Enter pin');
      await driver.enterText('12345');

      // Confirm pin
      await driver.waitFor(find.byValueKey('enrollment_confirm_pin'));

      // Check screen title
      print('check screen title Secure your irma app');
      string = await getTextFirstMatch(driver, find.byValueKey('irma_app_bar'));
      expect(string, 'Secure your IRMA app');

      // Check text
      print('check text Enter your pin');
      string = await driver.getText(find.descendant(
          of: find.byValueKey('enrollment_confirm_pin'), matching: find.byType('Text'), firstMatchOnly: true));
      expect(string, 'Enter your PIN again');

      await driver.enterText('12345');

      // Wait for screen to provide email address
      await driver.waitFor(find.byValueKey('enrollment_provide_email'));

      // Check screen title
      print('check screen title Secure your irma app');
      string = await getTextFirstMatch(driver, find.byValueKey('irma_app_bar'));
      expect(string, 'Secure your IRMA app');

      // Check text
      print('check text email enrollment');
      string = await driver.getText(find.descendant(
          of: find.byValueKey('enrollment_provide_email'), matching: find.byType('Text'), firstMatchOnly: true));
      expect(string, 'An email address allows you to disable your IRMA app when your mobile has been lost or stolen.');

      // Check textfield
      print('check textfield email');
      await driver.waitFor(find.descendant(
          of: find.byValueKey('enrollment_provide_email'), matching: find.byType('TextField'), firstMatchOnly: true));

      // Check buttons Skip & Next
      print('check buttons Skip & Next');
      await driver.waitFor(find.byValueKey('enrollment_skip_email'));
      await driver.waitFor(find.byValueKey('enrollment_email_next'));

      // Click Skip
      print('Skip Email');
      await driver.tap(find.byValueKey('enrollment_skip_email'));
      print('check irma dialog is displayed');
      await driver.waitFor(find.byValueKey('irma_dialog'));
      // Check dialog title text
      string = await driver.getText(find.byValueKey('irma_dialog_title'));
      expect(string, 'Are you sure?');
      // Check dialog text
      string = await driver.getText(find.byValueKey('irma_dialog_content'));
      expect(string,
          'Protect your data. When you enter an email address, you can block your IRMA app when your mobile has been lost or stolen.');

      // Confirm Skip
      await driver.tap(find.byValueKey('enrollment_skip_confirm'));

      // Wait until wallet displayed
      await driver.waitFor(find.byValueKey('wallet_present'));
      // No cards should be available in the wallet
      await driver.waitForAbsent(find.byValueKey('wallet_card_0'));
    }, timeout: const Timeout(Duration(minutes: 4)));

    test('irma-issuance-tc1', () async {
      // Scenario 1 of issuance process
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
      print('wait 5 seconds');
      await Future.delayed(const Duration(seconds: 5));
      print('Tap personal data card to open');
      await driver.tap(find.descendant(of: find.byValueKey('wallet_card_0'), matching: find.byValueKey('card_title')));
      print('wait 2 seconds');
      await Future.delayed(const Duration(seconds: 2));
      print('Checking Personal data card');
      String string = await driver
          .getText(find.descendant(of: find.byValueKey('wallet_card_0'), matching: find.byValueKey('card_title')));

      expect(string, 'Demo Personal data');

      print('Checking Names and values');

      print('checking initials');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_0_name', 'Initials');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_0_value', 'W.L.');

      print('checking First names');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_1_name', 'First names');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_1_value', 'Willeke Liselotte');

      print('checking Prefix');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_2_name', 'Prefix');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_2_value', 'de');

      print('checking Family name');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_3_name', 'Family name');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_3_value', 'Bruijn');

      print('checking Full name');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_4_name', 'Full name');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_4_value', 'W.L. de Bruijn');

      print('checking Gender');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_5_name', 'Gender');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_5_value', 'V');

      print('checking nationality');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_6_name', 'Dutch nationality');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_6_value', 'Ja');

      print('checking Surname');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_7_name', 'Surname');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_7_value', 'de Bruijn');

      print('checking Date of birth');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_8_name', 'Date of birth');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_8_value', '10-04-1965');

      print('checking City of birth');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_9_name', 'City of birth');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_9_value', 'Amsterdam');

      print('checking Country of birth');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_10_name', 'Country of birth');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_10_value', 'Nederland');

      print('checking Age');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_11_name', 'Over 12');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_11_value', 'Yes');

      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_12_name', 'Over 16');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_12_value', 'Yes');

      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_13_name', 'Over 18');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_13_value', 'Yes');

      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_14_name', 'Over 21');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_14_value', 'Yes');

      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_15_name', 'Over 65');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_15_value', 'No');

      print('Checking BSN');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_16_name', 'BSN');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_16_value', '999999990');

      print('checking DigiD assurance level');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_17_name', 'DigiD assurance level');
      await scrollAndCheckText(driver, 'wallet_card_0', 'attr_17_value', 'Substantieel');

      print('Tap personal data card to close');
      await driver.tap(find.descendant(of: find.byValueKey('wallet_card_0'), matching: find.byValueKey('card_title')));

      await Future.delayed(const Duration(seconds: 2));
      print('Tap Demo address card to open');
      await driver.tap(find.descendant(of: find.byValueKey('wallet_card_1'), matching: find.byValueKey('card_title')));
      await Future.delayed(const Duration(seconds: 2));

      print('Checking Demo address card');

      string = await driver
          .getText(find.descendant(of: find.byValueKey('wallet_card_1'), matching: find.byValueKey('card_title')));
      expect(string, 'Demo Address');
      print('Checking Gemeente adresgegevens - Names and values');

      print('Checking Address');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_0_name', 'Street');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_0_value', 'Meander');

      print('Checking Huisnummer');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_1_name', 'House number');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_1_value', '501');

      print('Checking Postcode');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_2_name', 'Zip code');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_2_value', '1234AB');

      print('Checking Gemeente');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_3_name', 'Municipality');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_3_value', 'Arnhem');

      print('Checking City');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_4_name', 'City');
      await scrollAndCheckText(driver, 'wallet_card_1', 'attr_4_value', 'Arnhem');
    }, timeout: const Timeout(Duration(minutes: 4)));
  });
}

Future<void> scrollAndCheckText(FlutterDriver driver, String parentKey, String textKey, String textValue) async {
  final widget = find.descendant(of: find.byValueKey(parentKey), matching: find.byValueKey(textKey));
  await driver.scrollIntoView(widget);
  final string = await driver.getText(widget);
  expect(string, textValue);
}

Future<String> getTextFirstMatch(FlutterDriver driver, SerializableFinder of) =>
    driver.getText(find.descendant(of: of, matching: find.byType('Text'), firstMatchOnly: true, matchRoot: true));

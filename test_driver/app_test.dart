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
      await driver.requestData(jsonEncode(data["sessionPtr"]));
    }

    test('irma-enroll-tc1', () async {


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
      //Enter Pin
      await driver.enterText('12345');
      // Enter wrong pin
      await driver.waitFor(find.byValueKey('enrollment_confirm_pin'));
      await driver.enterText('67890');

      await driver.waitFor(find.byValueKey('irma_dialog'));

      //check "Wrong PIN" dialog title text
      print("check dialog title");
      String string = await driver.getText(find.byValueKey('irma_dialog_title'));
      expect(string, 'PIN incorrect');
      print("Check dialog text");
      //check dialog text
      string = await driver.getText(find.byValueKey('irma_dialog_content'));
      expect(string, 'PINs do not match. Choose a new PIN.');
      print("escape dialog");
      await driver.tap(find.descendant(of: find.byValueKey('irma_dialog'), matching: find.byType('IrmaButton'), firstMatchOnly: true));





      // Choose new pin screen
      await driver.waitFor(find.byValueKey('enrollment_choose_pin'));
      //Enter Pin
      await driver.enterText('12345');
      // Enter wrong pin
      await driver.waitFor(find.byValueKey('enrollment_confirm_pin'));
      await driver.enterText('12345');

      //enter email address
      await driver.waitFor(find.byValueKey('enrollment_provide_email'));

      //check error message is not displayed
      await driver.waitForAbsent(find.descendant(of: find.byValueKey('enrollment_provide_email_textfield'), matching: find.text("This is not a valid email address")));

      await driver.enterText('Wrong_syntax');
      await driver.tap(find.byValueKey('enrollment_email_next'));

      //Check error message
      await driver.waitFor(find.descendant(of: find.byValueKey('enrollment_provide_email_textfield'), matching: find.text("This is not a valid email address")));

      //expect(string, 'This is not a valid email address');

      //check textfield is still present
      await driver.waitFor(find.descendant(of: find.byValueKey('enrollment_provide_email'), matching: find.byType('TextField'), firstMatchOnly: true));

      await driver.enterText('testing_irma_app@sidn.nl');
      await driver.tap(find.byValueKey('enrollment_email_next'));

      //wait for Email confirmation screen
      await driver.waitFor(find.byValueKey('email_sent_screen'));
      print("check screen title");
      //Check screen title
      string = await driver.getText(find.byValueKey('email_sent_screen_title'));
      expect(string, 'Secure your IRMA app');
      print("check text on email sent screen");
      //Check text
      string = await driver.getText(find.descendant(of: find.byValueKey('email_sent_screen'), matching: find.byType('Text'), firstMatchOnly: true));
      expect(string, 'Confirm your email address');

      //click continue
      await driver.tap(find.descendant(of: find.byValueKey('email_sent_screen_continue'), matching: find.byValueKey('primary')));

      // Wait until wallet displayed
      await driver.waitFor(find.byValueKey('wallet_present'));
      //No cards should be available in the wallet
      await driver.waitForAbsent(find.byValueKey('wallet_card_0'));


    }, timeout: const Timeout(Duration(minutes: 4)));

    test('irma-enroll-tc2', () async {


      //scenario 2

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

      //Check screen title
      String string = await driver.getText(find.byValueKey('enrollment_choose_pin_title'));
      expect(string, 'Secure your IRMA app');

      //Check text
      string = await driver.getText(find.descendant(of: find.byValueKey('enrollment_choose_pin'), matching: find.byType('Text'), firstMatchOnly: true));
      expect(string, 'Choose a 5-digit PIN');

      //Enter Pin
      await driver.enterText('12345');

      // Confirm pin
      await driver.waitFor(find.byValueKey('enrollment_confirm_pin'));

      //Check screen title
      string = await driver.getText(find.byValueKey('enrollment_confirm_pin_title'));
      expect(string, 'Secure your IRMA app');

      //Check text
      string = await driver.getText(find.descendant(of: find.byValueKey('enrollment_confirm_pin'), matching: find.byType('Text'), firstMatchOnly: true));
      expect(string, 'Enter your PIN again');

      await driver.enterText('12345');

      //Check screen title
      string = await driver.getText(find.byValueKey('enrollment_provide_email_title'));
      expect(string, 'Secure your IRMA app');

      //Check text
      string = await driver.getText(find.descendant(of: find.byValueKey('enrollment_provide_email'), matching: find.byType('Text'), firstMatchOnly: true));
      expect(string, 'An email address allows you to disable your IRMA app when your mobile has been lost or stolen.');

      //check textfield
      await driver.waitFor(find.descendant(of: find.byValueKey('enrollment_provide_email'), matching: find.byType('TextField'), firstMatchOnly: true));

      //check buttons Skip & Next
      await driver.waitFor(find.byValueKey('enrollment_skip_email'));
      await driver.waitFor(find.byValueKey('enrollment_email_next'));

      //click Skip
      print("Skip Email");
      await driver.tap(find.byValueKey('enrollment_skip_email'));
      print("check irma dialog is displayed");
      await driver.waitFor(find.byValueKey('irma_dialog'));
      print("check dialog title");
      //check dialog title text
      string = await driver.getText(find.byValueKey('irma_dialog_title'));
      expect(string, 'Are you sure?');
      print("check dialog text...");
      //check dialog text
      string = await driver.getText(find.byValueKey('irma_dialog_content'));
      print(string);
      expect(string, 'Protect your data. When you enter an email address, you can block your IRMA app when your mobile has been lost or stolen.');

      //confirm Skip
      await driver.tap(find.byValueKey('enrollment_skip_confirm'));


      // Wait until wallet displayed
      await driver.waitFor(find.byValueKey('wallet_present'));
      //No cards should be available in the wallet
      await driver.waitForAbsent(find.byValueKey('wallet_card_0'));

    }, timeout: const Timeout(Duration(minutes: 4)));
  });

}

Future<void> scrollAndCheckText(FlutterDriver driver, String parentKey, String textKey, String textValue) async {
  final widget = find.descendant(of: find.byValueKey(parentKey), matching: find.byValueKey(textKey));
  await driver.scrollIntoView(widget);
  final string = await driver.getText(widget);
  expect(string, textValue);
}

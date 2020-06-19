// Imports the Flutter Driver API.
import 'dart:async';

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
    });

    tearDownAll(() async {
      if (driver != null) await driver.close();
      if (streamSubscription != null) streamSubscription.cancel();
    });

    test('wait for boot', () async {
      // Tap through enrollment info screens
      await driver.tap(find.byValueKey('next_enrollment_p1'));
      await driver.tap(find.byValueKey('next_enrollment_p2'));
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

      // Continue to wallet
      await driver.tap(find.byValueKey('enrollment_success_continue'));
    });
  });
}

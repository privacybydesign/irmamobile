import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/util/nfc_settings.dart";

const _channel = MethodChannel("yivi.app/nfc_settings");

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test("opens the settings through the platform channel", () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call.method);
          return null;
        });

    await RealNfcSettingsOpener().open();

    expect(calls, ["open"]);
  });

  test("a device without an NFC settings screen is not an error", () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          throw PlatformException(code: "no_nfc_settings");
        });

    await expectLater(RealNfcSettingsOpener().open(), completes);
  });
}

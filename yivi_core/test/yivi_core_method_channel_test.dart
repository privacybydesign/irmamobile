import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/yivi_core_method_channel.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelYiviCore platform = MethodChannelYiviCore();
  const MethodChannel channel = MethodChannel("yivi_core");

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return "42";
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test("getPlatformVersion", () async {
    expect(await platform.getPlatformVersion(), "42");
  });
}

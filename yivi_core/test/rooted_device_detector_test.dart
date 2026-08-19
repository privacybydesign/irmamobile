import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/rooted_warning/rooted_device_detector.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel("yivi.app/root_detection");
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void answerWith(Object? value) => messenger.setMockMethodCallHandler(
    channel,
    (call) async => call.method == "isDeviceRooted" ? value : null,
  );

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test("reports what the platform says", () async {
    answerWith(true);
    expect(await RealRootedDeviceDetector().isDeviceRooted(), isTrue);

    answerWith(false);
    expect(await RealRootedDeviceDetector().isDeviceRooted(), isFalse);
  });

  test("no answer is not rooted, so the warning stays out of the way", () async {
    answerWith(null);
    expect(await RealRootedDeviceDetector().isDeviceRooted(), isFalse);
  });
}

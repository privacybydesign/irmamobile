import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/util/privacy_screen.dart";

/// Records what the `privacy_screen` channel is asked to do, so the balance of
/// suspend/resume calls is observable from a unit test.
List<String> _recordChannelCalls() {
  final calls = <String>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel("privacy_screen"), (
        call,
      ) async {
        calls.add(call.method);
        return true;
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel("privacy_screen"), null),
  );
  return calls;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("suspendDuring brackets the action and returns its value", () async {
    final calls = _recordChannelCalls();

    final result = await PrivacyScreen.suspendDuring(() async {
      expect(calls, ["suspendPrivacyScreen"]);
      return 42;
    });

    expect(result, 42);
    expect(calls, ["suspendPrivacyScreen", "resumePrivacyScreen"]);
  });

  test("suspendDuring resumes when the action throws", () async {
    final calls = _recordChannelCalls();

    await expectLater(
      PrivacyScreen.suspendDuring(() async => throw StateError("boom")),
      throwsStateError,
    );

    expect(calls, ["suspendPrivacyScreen", "resumePrivacyScreen"]);
  });

  test("suspendDuring nests: the inner flow does not resume early", () async {
    final calls = _recordChannelCalls();

    await PrivacyScreen.suspendDuring(() async {
      await PrivacyScreen.suspendDuring(() async {});
      // The outer flow is still running, so the privacy screen must still be
      // held back — the native side counts suspensions for exactly this.
      expect(calls, [
        "suspendPrivacyScreen",
        "suspendPrivacyScreen",
        "resumePrivacyScreen",
      ]);
    });

    expect(calls, [
      "suspendPrivacyScreen",
      "suspendPrivacyScreen",
      "resumePrivacyScreen",
      "resumePrivacyScreen",
    ]);
  });

  test("enable and disable leave the suspension count alone", () async {
    final calls = _recordChannelCalls();

    await PrivacyScreen.enablePrivacyScreen();
    await PrivacyScreen.disablePrivacyScreen();

    expect(calls, ["enablePrivacyScreen", "disablePrivacyScreen"]);
  });
}

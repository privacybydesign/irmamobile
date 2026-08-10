import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:local_auth/local_auth.dart";
import "package:yivi_core/src/screens/pin/providers/biometric_provider.dart";

class _FakeLocalAuth implements LocalAuthentication {
  _FakeLocalAuth({
    this.supported = true,
    this.canCheck = true,
    this.enrolled = const [BiometricType.fingerprint],
    this.error = false,
    this.promptSucceeds = true,
    this.promptThrows = false,
    this.onPrompt,
  });

  final bool supported;
  final bool canCheck;
  final List<BiometricType> enrolled;
  final bool error;
  final bool promptSucceeds;
  final bool promptThrows;

  /// Called while the OS prompt is notionally up, so a test can assert what the
  /// privacy screen was doing at that moment.
  final void Function()? onPrompt;

  @override
  Future<bool> isDeviceSupported() async {
    if (error) throw PlatformException(code: "err");
    return supported;
  }

  @override
  Future<bool> get canCheckBiometrics async => canCheck;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => enrolled;

  // authMessages is an Iterable<AuthMessages> upstream, but local_auth does not
  // export that type; widened to Object? so the override compiles without
  // depending on local_auth_platform_interface directly.
  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<Object?> authMessages = const [],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    onPrompt?.call();
    if (promptThrows) throw PlatformException(code: "NotAvailable");
    return promptSucceeds;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<bool> available(LocalAuthentication auth) {
  final container = ProviderContainer(
    overrides: [localAuthProvider.overrideWithValue(auth)],
  );
  addTearDown(container.dispose);
  return container.read(biometricAvailableProvider.future);
}

BiometricService service(LocalAuthentication auth) {
  final container = ProviderContainer(
    overrides: [localAuthProvider.overrideWithValue(auth)],
  );
  addTearDown(container.dispose);
  return container.read(biometricServiceProvider);
}

/// Records what the `privacy_screen` channel is asked to do during a test.
List<String> recordPrivacyScreenCalls() {
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

  test(
    "available when supported, can check, and a biometric is enrolled",
    () async {
      expect(await available(_FakeLocalAuth()), true);
    },
  );

  test("unavailable when the device is unsupported", () async {
    expect(await available(_FakeLocalAuth(supported: false)), false);
  });

  test("unavailable when no biometrics are enrolled", () async {
    expect(await available(_FakeLocalAuth(enrolled: [])), false);
  });

  test("unavailable when biometrics cannot be checked", () async {
    expect(await available(_FakeLocalAuth(canCheck: false)), false);
  });

  test("unavailable (not an error) when the platform check throws", () async {
    expect(await available(_FakeLocalAuth(error: true)), false);
  });

  test("authenticate holds the privacy screen back for the prompt", () async {
    final calls = recordPrivacyScreenCalls();
    late List<String> callsDuringPrompt;
    final auth = _FakeLocalAuth(
      onPrompt: () => callsDuringPrompt = List.of(calls),
    );

    expect(await service(auth).authenticate(localizedReason: "unlock"), true);

    // The blur must be held back for the whole prompt, not just switched off
    // and on around it: no enable/disable, so the user's screenshot preference
    // is never touched.
    expect(callsDuringPrompt, ["suspendPrivacyScreen"]);
    expect(calls, ["suspendPrivacyScreen", "resumePrivacyScreen"]);
  });

  test(
    "authenticate restores the privacy screen when the prompt throws",
    () async {
      final calls = recordPrivacyScreenCalls();
      final auth = _FakeLocalAuth(promptThrows: true);

      expect(
        await service(auth).authenticate(localizedReason: "unlock"),
        false,
      );

      expect(calls, ["suspendPrivacyScreen", "resumePrivacyScreen"]);
    },
  );

  test("authenticate reports a refused prompt as false", () async {
    recordPrivacyScreenCalls();
    final auth = _FakeLocalAuth(promptSucceeds: false);

    expect(await service(auth).authenticate(localizedReason: "unlock"), false);
  });
}

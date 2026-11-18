import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/screens/rooted_warning/repository.dart";

/// A rooted device and an untrusted environment (a hooking framework, an
/// emulator, a cloned app) are warned about and accepted separately.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The preferences of a user who has not accepted anything yet. The store
  /// behind them is shared between the tests, so it is reset here.
  Future<IrmaPreferences> preferences() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    await preferences.setAcceptedRootedRisk(false);
    await preferences.setAcceptedEnvironmentRisk(false);
    return preferences;
  }

  Stream<DeviceRisk?> pending(
    IrmaPreferences preferences, {
    bool rooted = false,
    bool untrustedEnvironment = false,
  }) => pendingDeviceRisk(
    preferences: preferences,
    rooted: Future.value(rooted),
    untrustedEnvironment: Future.value(untrustedEnvironment),
  );

  test("nothing to warn about on an ordinary device", () async {
    expect(await pending(await preferences()).first, isNull);
  });

  test("an earlier acceptance of the rooted warning does not silence the "
      "warning about the environment", () async {
    final prefs = await preferences();
    await prefs.setAcceptedRootedRisk(true);

    expect(
      await pending(prefs, untrustedEnvironment: true).first,
      DeviceRisk.untrustedEnvironment,
    );
    expect(
      await pending(prefs, rooted: true, untrustedEnvironment: true).first,
      DeviceRisk.untrustedEnvironment,
    );
  });

  test("accepting the environment does not silence the rooted "
      "warning", () async {
    final prefs = await preferences();
    await acceptDeviceRisk(prefs, DeviceRisk.untrustedEnvironment);

    expect(await pending(prefs, rooted: true).first, DeviceRisk.rooted);
  });

  test("with both, each is shown and accepted in turn", () async {
    final prefs = await preferences();
    final risks = <DeviceRisk?>[];
    final subscription = pending(
      prefs,
      rooted: true,
      untrustedEnvironment: true,
    ).listen(risks.add);
    await pumpEventQueue();
    expect(risks, [DeviceRisk.rooted]);

    await acceptDeviceRisk(prefs, DeviceRisk.rooted);
    await pumpEventQueue();
    expect(risks.last, DeviceRisk.untrustedEnvironment);

    await acceptDeviceRisk(prefs, DeviceRisk.untrustedEnvironment);
    await pumpEventQueue();
    expect(risks.last, isNull);

    await subscription.cancel();
  });

  test("each risk has its own explanation", () {
    expect(
      DeviceRisk.values.map((risk) => risk.explanationTranslationKey).toSet(),
      hasLength(DeviceRisk.values.length),
    );
  });
}

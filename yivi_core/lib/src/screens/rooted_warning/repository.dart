import "package:rxdart/rxdart.dart";

import "../../data/irma_preferences.dart";

/// A reason the app's protections cannot be relied on where it runs. The user
/// is warned about each one in its own words and accepts each one separately:
/// someone who accepted the risk of a rooted phone has not been told about a
/// hooking framework, an emulator or a cloned app.
enum DeviceRisk {
  /// The operating system is modified: a rooted or jailbroken device.
  rooted,

  /// A hooking framework, an emulator or an app-cloning container.
  untrustedEnvironment;

  String get explanationTranslationKey => switch (this) {
    rooted => "rooted_warning.explanation",
    untrustedEnvironment => "rooted_warning.explanation_environment",
  };
}

/// The risk the user still has to be warned about, or null when there is none
/// or every one that applies was accepted. With both, the rooted device comes
/// first and the environment follows once that one is accepted.
Stream<DeviceRisk?> pendingDeviceRisk({
  required IrmaPreferences preferences,
  required Future<bool> rooted,
  required Future<bool> untrustedEnvironment,
}) async* {
  final isRooted = await rooted;
  final isUntrustedEnvironment = await untrustedEnvironment;
  if (!isRooted && !isUntrustedEnvironment) {
    yield null;
    return;
  }
  yield* Rx.combineLatest2(
    preferences.getAcceptedRootedRisk(),
    preferences.getAcceptedEnvironmentRisk(),
    (acceptedRooted, acceptedEnvironment) {
      if (isRooted && !acceptedRooted) return DeviceRisk.rooted;
      if (isUntrustedEnvironment && !acceptedEnvironment) {
        return DeviceRisk.untrustedEnvironment;
      }
      return null;
    },
  );
}

Future<void> acceptDeviceRisk(IrmaPreferences preferences, DeviceRisk risk) =>
    switch (risk) {
      DeviceRisk.rooted => preferences.setAcceptedRootedRisk(true),
      DeviceRisk.untrustedEnvironment => preferences.setAcceptedEnvironmentRisk(
        true,
      ),
    };

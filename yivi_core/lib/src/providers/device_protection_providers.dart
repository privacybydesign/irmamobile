import "package:flutter_riverpod/flutter_riverpod.dart";

import "../screens/app_integrity/app_integrity.dart";
import "../screens/device_lock/device_security.dart";
import "../screens/rooted_warning/repository.dart";
import "app_integrity_provider.dart";
import "device_security_provider.dart";
import "preferences_provider.dart";
import "rooted_device_detector_provider.dart";

/// Watches for tampering while the app runs (see [AppIntegrityGuard]).
final appIntegrityGuardProvider = Provider<AppIntegrityGuard>((ref) {
  final guard = AppIntegrityGuard(ref.watch(appIntegrityProvider));
  ref.onDispose(guard.dispose);
  return guard;
});

/// Requires a screen lock on the device (see [DeviceLockRequirement]).
final deviceLockRequirementProvider = Provider<DeviceLockRequirement>((ref) {
  final requirement = DeviceLockRequirement(
    ref.watch(deviceSecurityProvider),
  );
  ref.onDispose(requirement.dispose);
  return requirement;
});

/// The device risk the user still has to be warned about: a rooted device,
/// then an untrusted environment; null when there is none left.
final pendingDeviceRiskProvider = StreamProvider<DeviceRisk?>(
  watchPendingDeviceRisk,
);

/// [pendingDeviceRiskProvider]'s stream, for a provider that combines it.
Stream<DeviceRisk?> watchPendingDeviceRisk(Ref ref) {
  final guard = ref.watch(appIntegrityGuardProvider);
  return pendingDeviceRisk(
    preferences: ref.watch(preferencesProvider),
    rooted: ref.watch(rootedDeviceDetectorProvider).isDeviceRooted(),
    untrustedEnvironment: guard.firstReport.then(
      (report) => report.untrustedEnvironment,
    ),
  );
}

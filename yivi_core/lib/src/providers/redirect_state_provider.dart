import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:rxdart/rxdart.dart";

import "../models/enrollment_status.dart";
import "../models/version_information.dart";
import "device_protection_providers.dart";
import "irma_repository_provider.dart";
import "preferences_provider.dart";

/// What decides where the router must send the user: tampering seen while the
/// app runs, a device without a screen lock, a device risk (rooted, or an
/// untrusted environment) that is not accepted, the name-changed notice, the
/// version information and the enrollment status.
class RedirectState {
  final bool integrityBlocked;
  final bool deviceLockRequired;
  final bool showRootedWarning;
  final bool showNameChanged;
  final VersionInformation? version;
  final EnrollmentStatus enrollment;

  const RedirectState({
    this.integrityBlocked = false,
    this.deviceLockRequired = false,
    required this.showRootedWarning,
    required this.showNameChanged,
    required this.version,
    required this.enrollment,
  });

  /// Before every input has a value: nothing redirects.
  static const initial = RedirectState(
    showRootedWarning: false,
    showNameChanged: false,
    version: null,
    enrollment: EnrollmentStatus.undetermined,
  );

  /// Where the router sends the user from [location], or null to let them go
  /// where they were going.
  String? redirect([String location = ""]) {
    if (integrityBlocked) return "/app_integrity_blocked";
    if (deviceLockRequired) return "/device_lock_required";
    // A screen lock was set: on from the page that asked for it.
    if (location == "/device_lock_required") return "/loading";
    if (showRootedWarning) return "/rooted_warning";
    if (enrollment == EnrollmentStatus.unenrolled) return "/enrollment";
    if (showNameChanged) return "/name_changed";
    if (version?.updateRequired() ?? false) return "/update_required";
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RedirectState &&
          integrityBlocked == other.integrityBlocked &&
          deviceLockRequired == other.deviceLockRequired &&
          showRootedWarning == other.showRootedWarning &&
          showNameChanged == other.showNameChanged &&
          version == other.version &&
          enrollment == other.enrollment;

  @override
  int get hashCode => Object.hash(
    integrityBlocked,
    deviceLockRequired,
    showNameChanged,
    showRootedWarning,
    version,
    enrollment,
  );

  @override
  String toString() =>
      "integrity blocked: $integrityBlocked, "
      "device lock required: $deviceLockRequired, enroll: $enrollment, "
      "rooted: $showRootedWarning, name: $showNameChanged, version: $version";
}

/// The redirect state, from its inputs. It has no value until each input has
/// given one, so nothing redirects before the first scheme rules arrive (or a
/// fatal error ends the version stream).
final redirectStateProvider = StreamProvider<RedirectState>((ref) {
  final repo = ref.watch(irmaRepositoryProvider);
  final prefs = ref.watch(preferencesProvider);
  final guard = ref.watch(appIntegrityGuardProvider);
  final deviceLock = ref.watch(deviceLockRequirementProvider);
  return Rx.combineLatest6(
    guard.blocked,
    deviceLock.lockRequired,
    // Waits for the checks: nothing redirects before they are known.
    watchPendingDeviceRisk(ref).map((risk) => risk != null),
    repo
        .getVersionInformation()
        .map<VersionInformation?>((version) => version)
        .defaultIfEmpty(null),
    prefs.showNameChangedNotification.stream,
    repo.getEnrollmentStatus(),
    (blocked, lockRequired, risk, version, nameChanged, enrollment) =>
        RedirectState(
          integrityBlocked: blocked,
          deviceLockRequired: lockRequired,
          showRootedWarning: risk,
          showNameChanged: nameChanged,
          version: version,
          enrollment: enrollment,
        ),
  ).distinct();
});

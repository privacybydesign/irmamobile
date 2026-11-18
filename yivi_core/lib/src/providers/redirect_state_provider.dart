import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:rxdart/rxdart.dart";

import "../models/enrollment_status.dart";
import "../models/version_information.dart";
import "../screens/rooted_warning/repository.dart";
import "irma_repository_provider.dart";
import "preferences_provider.dart";
import "rooted_device_detector_provider.dart";

/// What decides where the router must send the user: a rooted device whose
/// risk is not accepted, the name-changed notice, the version information
/// and the enrollment status.
class RedirectState {
  final bool showRootedWarning;
  final bool showNameChanged;
  final VersionInformation? version;
  final EnrollmentStatus enrollment;

  const RedirectState({
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

  /// Where the router sends the user, or null to let them go where they
  /// were going.
  String? redirect() {
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
          showRootedWarning == other.showRootedWarning &&
          showNameChanged == other.showNameChanged &&
          version == other.version &&
          enrollment == other.enrollment;

  @override
  int get hashCode =>
      Object.hash(showNameChanged, showRootedWarning, version, enrollment);

  @override
  String toString() =>
      "enroll: $enrollment, rooted: $showRootedWarning, "
      "name: $showNameChanged, version: $version";
}

/// The redirect state, from its four inputs. It has no value until each
/// input has given one, so nothing redirects before the first scheme rules
/// arrive (or a fatal error ends the version stream).
final redirectStateProvider = StreamProvider<RedirectState>((ref) {
  final repo = ref.watch(irmaRepositoryProvider);
  final prefs = ref.watch(preferencesProvider);
  final rooted = DetectRootedDeviceIrmaPrefsRepository(
    preferences: prefs,
    detector: ref.watch(rootedDeviceDetectorProvider),
  );
  return Rx.combineLatest4(
    _rootedWarning(rooted),
    repo
        .getVersionInformation()
        .map<VersionInformation?>((version) => version)
        .defaultIfEmpty(null),
    prefs.showNameChangedNotification.stream,
    repo.getEnrollmentStatus(),
    (rooted, version, nameChanged, enrollment) => RedirectState(
      showRootedWarning: rooted,
      showNameChanged: nameChanged,
      version: version,
      enrollment: enrollment,
    ),
  ).distinct();
});

/// Whether the rooted-device warning must show: only on a rooted device,
/// until its risk is accepted.
Stream<bool> _rootedWarning(DetectRootedDeviceRepository rooted) async* {
  if (await rooted.isDeviceRooted()) {
    yield* rooted.hasAcceptedRootedDeviceRisk().map((accepted) => !accepted);
  } else {
    yield false;
  }
}

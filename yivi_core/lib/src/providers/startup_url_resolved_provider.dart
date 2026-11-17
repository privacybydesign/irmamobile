import "stream_mirror.dart";

/// `repo.getStartupUrlResolved()`: `false` until native acknowledges the
/// launch handshake, `true` afterwards. The lock-screen [PinScreen] gates its
/// cold-start biometric auto-scan on this so biometric can't win the race
/// against a universal link and unlock the app before the session pointer
/// that launched it is known, which would otherwise let a link session ride
/// in on a biometric-only unlock (issue #644).
final startupUrlResolvedProvider = mirrorProvider<bool>(
  (repo) => repo.getStartupUrlResolved(),
  first: (_) => false,
);

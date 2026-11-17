import "stream_mirror.dart";

/// `repo.getLocked()` as a provider, so widgets `ref.watch` it instead of
/// building a StreamBuilder.
///
/// The first value is `true` ("lock by default"): `_lockedSubject` in the
/// repo is itself seeded `true`, so the subscription confirms it on the
/// first emission. Treating "unknown" as locked is the safe choice if
/// anything ever races.
final appLockedProvider = mirrorProvider<bool>(
  (repo) => repo.getLocked(),
  first: (_) => true,
);

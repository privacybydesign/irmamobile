import "stream_mirror.dart";

/// `AppLock.locked` as a provider, so widgets `ref.watch` it instead of
/// building a StreamBuilder.
///
/// The first value is `true` ("lock by default"): the lock is itself seeded
/// `true`, so the subscription confirms it on the
/// first emission. Treating "unknown" as locked is the safe choice if
/// anything ever races.
final appLockedProvider = mirrorProvider<bool>(
  (repo) => repo.appLock.locked,
  first: (_) => true,
);

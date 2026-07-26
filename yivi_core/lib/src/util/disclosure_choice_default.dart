import "../models/credential_usage.dart";
import "../models/schemaless/session_state.dart";

/// Index of the option to pre-select in a disclosure choice, for a user who has
/// not picked one yet.
///
/// [options] is expected in chronological order (as [DisclosurePickOne] hands
/// it out). The order itself is left alone; only which one starts out selected
/// is decided here, by priority:
///
/// 1. An option that can still be disclosed, over one that is expired, revoked
///    or out of batch instances.
/// 2. Among those, the one disclosed most often.
/// 3. Among equally used ones, the one disclosed most recently, then the
///    chronologically first.
///
/// When nothing can be disclosed, the first option is selected, matching what
/// the screen did before there was anything to choose on: the confirm button is
/// disabled in that case anyway.
int defaultDisclosureBundleIndex(
  List<DisclosureBundle> options, {
  required Map<String, CredentialUsage> usage,
  required DateTime now,
}) {
  if (options.length <= 1) return 0;

  var bestIndex = -1;
  _BundleUsage? best;
  for (var i = 0; i < options.length; i++) {
    if (!options[i].isSharableAt(now)) continue;
    final candidate = _usageOf(options[i], usage);
    if (best == null || candidate.beats(best)) {
      bestIndex = i;
      best = candidate;
    }
  }
  return bestIndex == -1 ? 0 : bestIndex;
}

/// How often a bundle as a whole was disclosed.
///
/// A bundle is disclosed atomically, so every credential in it is counted in
/// the same session — which makes the least-used credential the number of times
/// the bundle itself was used. A credential with no record at all counts as
/// zero, so a bundle containing one has never been disclosed as a bundle.
_BundleUsage _usageOf(
  DisclosureBundle bundle,
  Map<String, CredentialUsage> usage,
) {
  var count = 0;
  var lastUsedEpochMs = 0;
  for (var i = 0; i < bundle.credentials.length; i++) {
    final credentialUsage = usage[bundle.credentials[i].hash];
    final credentialCount = credentialUsage?.count ?? 0;
    final credentialLastUsed =
        credentialUsage?.lastUsed.millisecondsSinceEpoch ?? 0;
    if (i == 0 || credentialCount < count) count = credentialCount;
    if (i == 0 || credentialLastUsed < lastUsedEpochMs) {
      lastUsedEpochMs = credentialLastUsed;
    }
  }
  return _BundleUsage(count: count, lastUsedEpochMs: lastUsedEpochMs);
}

class _BundleUsage {
  final int count;
  final int lastUsedEpochMs;

  const _BundleUsage({required this.count, required this.lastUsedEpochMs});

  bool beats(_BundleUsage other) => count != other.count
      ? count > other.count
      : lastUsedEpochMs > other.lastUsedEpochMs;
}

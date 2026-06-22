import "../../../models/schemaless/session_state.dart";

/// Pure selection helpers shared by the disclosure overview and the
/// make-choice screen.
///
/// Disclosure selection must be robust to the owned-options list changing
/// underneath the UI — most importantly when a credential is deleted while a
/// session is in progress, which removes (and thereby shifts the position of)
/// entries in [DisclosurePickOne.ownedOptions]. Keying a selection on a list
/// *index* breaks in that case: the index that pointed at the user's chosen
/// credential ends up pointing at whatever credential shifted into that slot,
/// so a different credential gets disclosed (see issue #520).
///
/// The fix is to key the selection on a stable identity — the set of
/// credential hashes of the selected bundle — and re-resolve the index (or the
/// bundle itself) against the current list whenever it is needed.

/// Returns the index of the bundle in [owned] whose credential hashes equal
/// [selectedHashes], or `null` when no bundle matches.
///
/// Bundle identity is determined by *set equality* over credential hashes.
/// Two distinct bundles whose credentials hash to the same set map to the
/// first matching index — acceptable because in that case the disclosed
/// payload is identical.
int? selectedBundleIndex(
  List<DisclosureBundle> owned,
  Set<String> selectedHashes,
) {
  for (var i = 0; i < owned.length; i++) {
    final bundleHashes = owned[i].credentialHashes;
    if (bundleHashes.length == selectedHashes.length &&
        bundleHashes.containsAll(selectedHashes)) {
      return i;
    }
  }
  return null;
}

/// Returns the bundle in [owned] whose credential hashes equal
/// [selectedHashes], or `null` when no bundle matches (e.g. the selected
/// credential was deleted, or re-issued with a new hash).
DisclosureBundle? resolveSelectedBundle(
  List<DisclosureBundle> owned,
  Set<String> selectedHashes,
) {
  final index = selectedBundleIndex(owned, selectedHashes);
  return index == null ? null : owned[index];
}

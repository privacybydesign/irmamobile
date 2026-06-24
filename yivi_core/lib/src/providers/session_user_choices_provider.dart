import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/schemaless/session_state.dart";
import "session_state_provider.dart";

class SessionUserChoices {
  final Map<int, DisclosureBundle> disclosureChoices;
  final Set<int> addedOptionalIndices;

  const SessionUserChoices({
    this.disclosureChoices = const {},
    this.addedOptionalIndices = const {},
  });

  SessionUserChoices withBundle(int disconIndex, DisclosureBundle bundle) {
    return SessionUserChoices(
      disclosureChoices: {...disclosureChoices, disconIndex: bundle},
      addedOptionalIndices: addedOptionalIndices,
    );
  }

  SessionUserChoices withOptionalAdded(int disconIndex) {
    return SessionUserChoices(
      disclosureChoices: disclosureChoices,
      addedOptionalIndices: {...addedOptionalIndices, disconIndex},
    );
  }

  SessionUserChoices withOptionalRemoved(int disconIndex) {
    return SessionUserChoices(
      disclosureChoices: Map.of(disclosureChoices)..remove(disconIndex),
      addedOptionalIndices: Set.of(addedOptionalIndices)..remove(disconIndex),
    );
  }
}

class SessionUserChoicesNotifier extends Notifier<SessionUserChoices> {
  final int sessionId;

  /// Tracks which owned credential hashes existed per discon index (flattened
  /// across bundles), so we can detect newly issued credentials and auto-select
  /// the bundle containing them.
  Map<int, Set<String>> _previousOwnedHashes = {};

  SessionUserChoicesNotifier(this.sessionId);

  @override
  SessionUserChoices build() {
    final session = ref.read(sessionStateProvider(sessionId)).value;
    if (session != null) {
      _previousOwnedHashes = _buildOwnedHashesMap(
        session.disclosurePlan?.disclosureChoicesOverview ?? [],
      );
    }

    ref.listen(sessionStateProvider(sessionId), (previous, next) {
      final session = next.value;
      if (session != null) {
        _autoSelectNewlyIssuedCredentials(session);
      }
    });

    return const SessionUserChoices();
  }

  void setBundle(int disconIndex, DisclosureBundle bundle) {
    state = state.withBundle(disconIndex, bundle);
  }

  void addOptional(int disconIndex) {
    state = state.withOptionalAdded(disconIndex);
  }

  void removeOptional(int disconIndex) {
    state = state.withOptionalRemoved(disconIndex);
  }

  void _autoSelectNewlyIssuedCredentials(SessionState session) {
    final choices = session.disclosurePlan?.disclosureChoicesOverview ?? [];
    final currentHashes = _buildOwnedHashesMap(choices);

    if (_previousOwnedHashes.isNotEmpty) {
      var updated = state;
      var changed = false;
      for (var i = 0; i < choices.length; i++) {
        final bundles = choices[i].ownedOptions ?? [];
        final existing = updated.disclosureChoices[i];
        final target = newlyIssuedBundleToSelect(
          ownedOptions: bundles,
          previousHashes: _previousOwnedHashes[i] ?? {},
          currentSelection: existing,
        );

        if (target != null && target != existing) {
          updated = updated.withBundle(i, target);
          changed = true;
        }
      }
      if (changed) state = updated;
    }

    _previousOwnedHashes = currentHashes;
  }

  /// Picks the owned bundle that should become selected for a discon after a
  /// disclosure-session state update, or `null` if the selection should not
  /// change.
  ///
  /// A credential counts as newly issued when its hash is absent from
  /// [previousHashes] (the owned hashes seen in the previous state). The
  /// selection moves to the **bottom-most** owned bundle that contains a
  /// newly-issued credential. Newly obtained credentials are appended to the
  /// end of `ownedOptions`, so the bottom-most match is the freshly obtained
  /// option — matching the requirement that a newly obtained attribute lands
  /// at the bottom of the list and becomes selected (issue #298). Selecting
  /// the *last* match (rather than the first) keeps that guarantee even when
  /// more than one bundle contains a newly-issued credential.
  ///
  /// If the user's [currentSelection] already contains a newly-issued
  /// credential it is kept, so a credential shared across bundles does not
  /// silently switch the user's existing choice.
  static DisclosureBundle? newlyIssuedBundleToSelect({
    required List<DisclosureBundle> ownedOptions,
    required Set<String> previousHashes,
    DisclosureBundle? currentSelection,
  }) {
    bool hasNew(DisclosureBundle b) =>
        b.credentialHashes.any((h) => !previousHashes.contains(h));

    if (currentSelection != null && hasNew(currentSelection)) {
      return currentSelection;
    }

    DisclosureBundle? target;
    for (final bundle in ownedOptions) {
      // Keep the last match so the bottom-most newly-issued bundle wins.
      if (hasNew(bundle)) target = bundle;
    }
    return target;
  }

  static Map<int, Set<String>> _buildOwnedHashesMap(
    List<DisclosurePickOne> choices,
  ) {
    return {
      for (var i = 0; i < choices.length; i++)
        i: {
          for (final bundle in choices[i].ownedOptions ?? [])
            for (final cred in bundle.credentials) cred.hash,
        },
    };
  }
}

final sessionUserChoicesProvider =
    NotifierProvider.family<
      SessionUserChoicesNotifier,
      SessionUserChoices,
      int
    >((sessionId) => SessionUserChoicesNotifier(sessionId));

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
        final previousHashes = _previousOwnedHashes[i] ?? {};

        bool hasNew(DisclosureBundle b) =>
            b.credentialHashes.any((h) => !previousHashes.contains(h));

        // Prefer the bundle the user already selected if it also contains a
        // newly-issued credential. This avoids silently switching the user's
        // choice when a credential is shared across bundles.
        final existing = updated.disclosureChoices[i];
        DisclosureBundle? target;
        if (existing != null && hasNew(existing)) {
          target = existing;
        } else {
          for (final bundle in bundles) {
            if (hasNew(bundle)) {
              target = bundle;
              break;
            }
          }
        }

        if (target != null && target != existing) {
          updated = updated.withBundle(i, target);
          changed = true;
        }
      }
      if (changed) state = updated;
    }

    _previousOwnedHashes = currentHashes;
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

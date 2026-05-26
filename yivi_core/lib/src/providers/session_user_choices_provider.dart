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
      for (var i = 0; i < choices.length; i++) {
        final bundles = choices[i].ownedOptions ?? [];
        final previousHashes = _previousOwnedHashes[i] ?? {};

        for (final bundle in bundles) {
          if (bundle.credentialHashes.any((h) => !previousHashes.contains(h))) {
            updated = updated.withBundle(i, bundle);
            break;
          }
        }
      }
      state = updated;
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

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/schemaless/session_state.dart";
import "../models/schemaless/session_user_interaction.dart";
import "session_state_provider.dart";

class SessionUserChoices {
  final Map<int, SelectedCredential> disclosureChoices;
  final Set<int> addedOptionalIndices;

  const SessionUserChoices({
    this.disclosureChoices = const {},
    this.addedOptionalIndices = const {},
  });

  SessionUserChoices withChoice(
    int disconIndex,
    SelectedCredential credential,
  ) {
    return SessionUserChoices(
      disclosureChoices: {...disclosureChoices, disconIndex: credential},
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

  /// Tracks which owned credential hashes existed per discon index,
  /// so we can detect newly issued credentials and auto-select them.
  Map<int, Set<String>> _previousOwnedHashes = {};

  SessionUserChoicesNotifier(this.sessionId);

  @override
  SessionUserChoices build() {
    // Snapshot the initial owned hashes
    final session = ref.read(sessionStateProvider(sessionId)).value;
    if (session != null) {
      _previousOwnedHashes = _buildOwnedHashesMap(
        session.disclosurePlan?.disclosureChoicesOverview ?? [],
      );
    }

    // Listen for session state changes to auto-select newly issued credentials
    ref.listen(sessionStateProvider(sessionId), (previous, next) {
      final session = next.value;
      if (session != null) {
        _autoSelectNewlyIssuedCredentials(session);
      }
    });

    return const SessionUserChoices();
  }

  void setChoice(int disconIndex, SelectedCredential credential) {
    state = state.withChoice(disconIndex, credential);
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
        final owned = choices[i].ownedOptions ?? [];
        final previousHashes = _previousOwnedHashes[i] ?? {};

        for (final cred in owned) {
          if (!previousHashes.contains(cred.hash)) {
            updated = updated.withChoice(
              i,
              SelectedCredential(
                credentialId: cred.credentialId,
                credentialHash: cred.hash,
                attributePaths: cred.attributes
                    .map((attr) => <dynamic>[attr.id])
                    .toList(),
              ),
            );
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
        i: {for (final owned in choices[i].ownedOptions ?? []) owned.hash},
    };
  }
}

final sessionUserChoicesProvider =
    NotifierProvider.family<
      SessionUserChoicesNotifier,
      SessionUserChoices,
      int
    >((sessionId) => SessionUserChoicesNotifier(sessionId));

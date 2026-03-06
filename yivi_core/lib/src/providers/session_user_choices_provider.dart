import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/schemaless/session_user_interaction.dart";

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
  @override
  SessionUserChoices build() => const SessionUserChoices();

  void setChoice(int disconIndex, SelectedCredential credential) {
    state = state.withChoice(disconIndex, credential);
  }

  void addOptional(int disconIndex) {
    state = state.withOptionalAdded(disconIndex);
  }

  void removeOptional(int disconIndex) {
    state = state.withOptionalRemoved(disconIndex);
  }
}

final sessionUserChoicesProvider =
    NotifierProvider.family<
      SessionUserChoicesNotifier,
      SessionUserChoices,
      int
    >((sessionId) => SessionUserChoicesNotifier());

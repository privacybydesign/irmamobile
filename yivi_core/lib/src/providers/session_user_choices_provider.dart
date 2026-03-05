import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/schemaless/session_user_interaction.dart";

class SessionUserChoices {
  final Map<int, SelectedCredential> disclosureChoices;

  const SessionUserChoices({this.disclosureChoices = const {}});

  SessionUserChoices withChoice(
    int disconIndex,
    SelectedCredential credential,
  ) {
    return SessionUserChoices(
      disclosureChoices: {...disclosureChoices, disconIndex: credential},
    );
  }
}

class SessionUserChoicesNotifier extends Notifier<SessionUserChoices> {
  @override
  SessionUserChoices build() => const SessionUserChoices();

  void setChoice(int disconIndex, SelectedCredential credential) {
    state = state.withChoice(disconIndex, credential);
  }
}

final sessionUserChoicesProvider =
    NotifierProvider.family<
      SessionUserChoicesNotifier,
      SessionUserChoices,
      int
    >((sessionId) => SessionUserChoicesNotifier());

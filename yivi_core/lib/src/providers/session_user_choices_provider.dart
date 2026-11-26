import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/session_state.dart";
import "../screens/session/models/disclosure_plan_view.dart";
import "last_shared_provider.dart";
import "session_state_provider.dart";

/// What the user picked in the request of session [sessionId]. A card issued
/// while the request waits is picked as soon as it arrives: its slot's card,
/// its option and, for an optional choice, sharing it.
class DisclosureSelectionNotifier extends Notifier<DisclosureSelection> {
  final int sessionId;

  /// The candidate hashes per slot id in the last plan seen, so a card that
  /// was not there before is recognised.
  Map<String, Set<String>> _previous = const {};

  DisclosureSelectionNotifier(this.sessionId);

  @override
  DisclosureSelection build() {
    _previous = _candidatesBySlot(
      ref.read(sessionStateProvider(sessionId)).value?.disclosurePlan,
    );
    ref.listen(sessionStateProvider(sessionId), (_, next) {
      if (next.value?.disclosurePlan case final plan?) _pickNewCards(plan);
    });
    return const DisclosureSelection();
  }

  void chooseOption(int choice, int option) =>
      state = state.withOption(choice, option);

  void chooseCards(String slotId, List<String> hashes) =>
      state = state.withCards(slotId, hashes);

  void share(int choice, {required bool on}) =>
      state = state.withOptional(choice, on: on);

  /// Picks the card with [hash] wherever the plan has it: its card, its
  /// option and, for an optional choice, sharing it. False when the plan has
  /// no such candidate.
  bool preferCard(DisclosurePlan plan, String hash) {
    var next = state;
    var found = false;
    for (final (i, choice) in plan.choices.indexed) {
      for (final (o, option) in choice.options.indexed) {
        for (final slot in option.slots) {
          final has = slot.candidates.any((c) => c.hash == hash && usable(c));
          if (!has) continue;
          found = true;
          next = next.withCards(slot.id, [hash]).withOption(i, o);
          if (choice.optional) next = next.withOptional(i, on: true);
        }
      }
    }
    if (found) state = next;
    return found;
  }

  void _pickNewCards(DisclosurePlan plan) {
    final current = _candidatesBySlot(plan);
    if (_previous.isNotEmpty) {
      final added = {
        for (final entry in current.entries)
          for (final hash in entry.value)
            if (!(_previous[entry.key]?.contains(hash) ?? false)) hash,
      };
      for (final hash in added) {
        preferCard(plan, hash);
      }
    }
    _previous = current;
  }

  static Map<String, Set<String>> _candidatesBySlot(DisclosurePlan? plan) => {
    for (final choice in plan?.choices ?? const <DisclosureChoice>[])
      for (final option in choice.options)
        for (final slot in option.slots)
          slot.id: {for (final c in slot.candidates) c.hash},
  };
}

final disclosureSelectionProvider =
    NotifierProvider.family<
      DisclosureSelectionNotifier,
      DisclosureSelection,
      int
    >((sessionId) => DisclosureSelectionNotifier(sessionId));

/// The choices of the request of [sessionId] that needed work when it opened:
/// the add step's rows, kept (with a check) after they are done. Set once,
/// from the first plan.
class FixedChoicesNotifier extends Notifier<List<int>?> {
  final int sessionId;

  FixedChoicesNotifier(this.sessionId);

  @override
  List<int>? build() {
    final first = _of(ref.read(sessionStateProvider(sessionId)).value);
    if (first == null) {
      ref.listen(sessionStateProvider(sessionId), (_, next) {
        if (state == null) state = _of(next.value);
      });
    }
    return first;
  }

  static List<int>? _of(SessionState? session) {
    final plan = session?.disclosurePlan;
    if (plan == null) return null;
    return [
      for (final (i, choice) in plan.choices.indexed)
        if (needsWork(choice)) i,
    ];
  }
}

final fixedChoicesProvider =
    NotifierProvider.family<FixedChoicesNotifier, List<int>?, int>(
      (sessionId) => FixedChoicesNotifier(sessionId),
    );

/// The request of [sessionId] with the user's selection and what was shared
/// before worked out ([resolve]); null while there is no plan.
final chosenProvider = Provider.autoDispose.family<Chosen?, int>((
  ref,
  sessionId,
) {
  final plan = ref.watch(sessionStateProvider(sessionId)).value?.disclosurePlan;
  if (plan == null) return null;
  return resolve(
    plan,
    ref.watch(disclosureSelectionProvider(sessionId)),
    sharesOf: ref.watch(sharesOfProvider(sessionId)),
  );
});

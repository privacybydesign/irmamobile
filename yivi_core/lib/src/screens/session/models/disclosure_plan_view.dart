import "dart:convert";

import "package:collection/collection.dart";

import "../../../models/credential.dart";
import "../../../models/credential_store.dart";
import "../../../models/session_state.dart";
import "../../../models/session_user_interaction.dart";
import "../../../util/string.dart";

// What the disclosure screens show, worked out from the plan irmago sends
// (choices → options → slots → candidates), the user's selection, and what
// was shared before. Pure functions returning what to show (not the words:
// the screens turn these into strings), so every rule can be unit tested
// without pumping a screen.

// --- The selection -----------------------------------------------------------

/// What the user picked in a request. Absent entries fall back to the
/// defaults ([defaultOption], [defaultCards]).
class DisclosureSelection {
  /// Choice index → option index.
  final Map<int, int> option;

  /// Slot id → the hashes of the chosen cards. Keyed by slot id alone
  /// ([selectionKey]), so a DCQL query in several options or credential sets
  /// is one selection everywhere.
  final Map<String, List<String>> cards;

  /// The optional choices that are shared.
  final Set<int> optionalOn;

  const DisclosureSelection({
    this.option = const {},
    this.cards = const {},
    this.optionalOn = const {},
  });

  DisclosureSelection withOption(int choice, int option) => DisclosureSelection(
    option: {...this.option, choice: option},
    cards: cards,
    optionalOn: optionalOn,
  );

  DisclosureSelection withCards(String slotId, List<String> hashes) =>
      DisclosureSelection(
        option: option,
        cards: {...cards, slotId: hashes},
        optionalOn: optionalOn,
      );

  DisclosureSelection withOptional(int choice, {required bool on}) =>
      DisclosureSelection(
        option: option,
        cards: cards,
        optionalOn: on
            ? {...optionalOn, choice}
            : ({...optionalOn}..remove(choice)),
      );
}

/// The key a slot's selection is kept under: its id. A query that sits in
/// two credential sets is then one choice wherever it appears (IRMA slot ids
/// carry their discon, so they never join).
String selectionKey(DisclosureSlot slot) => slot.id;

/// When a card was last shared: with this requestor, and with anyone.
class LastShared {
  final DateTime? withRequestor;
  final DateTime? withAnyone;

  const LastShared({this.withRequestor, this.withAnyone});

  static const never = LastShared();
}

/// What was shared before, per candidate hash.
typedef SharesOf = LastShared Function(String hash);

LastShared _never(String _) => LastShared.never;

// --- Cards and slots -----------------------------------------------------------

/// Whether [candidate] can be shared for this request: irmago's verdict,
/// never derived in the app from dates or flags.
bool usable(SelectableCredentialInstance candidate) => candidate.usable;

/// Whether every slot of [option] has a usable card.
bool complete(DisclosureOption option) =>
    option.slots.every((slot) => slot.candidates.any(usable));

/// Whether [choice] is required and cannot be answered yet.
bool needsWork(DisclosureChoice choice) =>
    !choice.optional && !choice.options.any(complete);

/// Whether [choice] is big: some option needs more than one card.
bool isBig(DisclosureChoice choice) =>
    choice.options.any((o) => o.slots.length > 1);

/// Whether every required choice of [plan] can be answered.
bool canShare(DisclosurePlan plan) => !plan.choices.any(needsWork);

/// Whether every choice of [plan] is optional (and there is one at all).
bool nothingRequired(DisclosurePlan plan) =>
    plan.choices.isNotEmpty && plan.choices.every((c) => c.optional);

/// Whether Yivi can send the user to get [descriptor]: it has an issue URL.
bool canBeAdded(CredentialDescriptor descriptor) =>
    hostOf(descriptor.issueURL) != null;

/// Whether a card of [slot]'s kind can be added (again): one of its
/// descriptors has an issue URL. irmago only offers another card of a type
/// that is not a singleton next to a usable one.
bool canAddAnother(DisclosureSlot slot) => slot.obtainable.any(canBeAdded);

/// The descriptor to add for [slot]: the first that Yivi can add, else the
/// first (which says what is asked).
CredentialDescriptor? addableFor(DisclosureSlot slot) =>
    slot.obtainable.firstWhereOrNull(canBeAdded) ?? slot.obtainable.firstOrNull;

/// The name of [slot]'s kind: of its first card, else of what it offers to
/// add.
String slotName(DisclosureSlot slot) =>
    slot.candidates.firstOrNull?.name ??
    slot.obtainable.firstOrNull?.name ??
    slot.id;

/// The issuer of [slot]'s kind, as for [slotName].
TrustedParty? slotIssuer(DisclosureSlot slot) =>
    slot.candidates.firstOrNull?.issuer ?? slot.obtainable.firstOrNull?.issuer;

/// The credential type id of [slot]'s cards.
String slotType(DisclosureSlot slot) =>
    slot.candidates.firstOrNull?.credentialId ??
    slot.obtainable.firstOrNull?.credentialId ??
    slot.id;

/// Why a card cannot be shared: irmago's `unusable_reason`.
enum CardProblem { revoked, expired, usedUp, notRevocable }

CardProblem? problemOf(SelectableCredentialInstance candidate) =>
    candidate.usable
    ? null
    : switch (candidate.unusableReason) {
        UnusableReason.revoked => CardProblem.revoked,
        UnusableReason.expired => CardProblem.expired,
        UnusableReason.usedUp => CardProblem.usedUp,
        UnusableReason.notRevocable => CardProblem.notRevocable,
        null => CardProblem.expired,
      };

/// The problem of a slot without a usable card that has cards: of its first
/// card. Null when it has a usable card, or none at all.
CardProblem? slotProblem(DisclosureSlot slot) => slot.candidates.any(usable)
    ? null
    : slot.candidates.map(problemOf).firstOrNull;

/// The slots of [option] still without a usable card.
List<DisclosureSlot> todoSlots(DisclosureOption option) => [
  for (final slot in option.slots)
    if (!slot.candidates.any(usable)) slot,
];

/// Whether Yivi can get every card [option] still misses.
bool canComplete(DisclosureOption option) =>
    todoSlots(option).every((slot) => slot.obtainable.any(canBeAdded));

// --- Identical cards (D3) --------------------------------------------------------

/// Cards of one slot that share exactly the same values: one row. [first] is
/// the card the row stands for.
class CandidateGroup {
  final List<SelectableCredentialInstance> cards;

  const CandidateGroup(this.cards);

  SelectableCredentialInstance get first => cards.first;
  int get count => cards.length;
  bool get usable => first.usable;
}

/// The candidates of [slot] grouped by what they share (names and the full
/// nested values), in candidate order. An unusable card never joins a usable
/// one.
List<CandidateGroup> groupsOf(DisclosureSlot slot) {
  final groups = <String, List<SelectableCredentialInstance>>{};
  for (final card in slot.candidates) {
    groups.putIfAbsent(_sharedValuesKey(card), () => []).add(card);
  }
  return [for (final cards in groups.values) CandidateGroup(cards)];
}

String _sharedValuesKey(SelectableCredentialInstance card) => jsonEncode([
  card.usable,
  card.credentialId,
  for (final a in card.attributes)
    [a.claimPath, a.displayName, a.value?.toJson()],
]);

// --- Defaults and what is chosen ---------------------------------------------------

/// The card(s) [slot] starts on (2.6): all usable cards for a multiple
/// slot; else the card last shared with this requestor, else last shared
/// with anyone, else the first usable card, passing over [taken] (the cards
/// of the option's other slots) where it can.
List<SelectableCredentialInstance> defaultCards(
  DisclosureSlot slot, {
  SharesOf sharesOf = _never,
  Set<String> taken = const {},
}) {
  final cards = slot.candidates.where(usable).toList();
  if (cards.isEmpty) return const [];
  if (slot.multiple) return cards;
  int latestFirst(DateTime? a, DateTime? b) =>
      a == null ? (b == null ? 0 : 1) : (b == null ? -1 : b.compareTo(a));
  final ranked = [...cards]
    ..sort((a, b) {
      final sa = sharesOf(a.hash), sb = sharesOf(b.hash);
      final them = latestFirst(sa.withRequestor, sb.withRequestor);
      if (them != 0) return them;
      return latestFirst(sa.withAnyone, sb.withAnyone);
    });
  return [
    ranked.firstWhereOrNull((c) => !taken.contains(c.hash)) ?? ranked.first,
  ];
}

/// The option [choice] starts on (2.6): the complete option last shared with
/// this requestor (all its slots), else the first complete one; -1 when none
/// is complete.
int defaultOption(DisclosureChoice choice, {SharesOf sharesOf = _never}) {
  DateTime? lastShared(DisclosureOption option) {
    DateTime? last;
    for (final slot in option.slots) {
      final times = [
        for (final c in slot.candidates.where(usable))
          ?sharesOf(c.hash).withRequestor,
      ];
      if (times.isEmpty) return null;
      final latest = times.reduce((a, b) => a.isAfter(b) ? a : b);
      if (last == null || latest.isAfter(last)) last = latest;
    }
    return last;
  }

  var best = -1;
  DateTime? bestAt;
  for (final (o, option) in choice.options.indexed) {
    if (!complete(option)) continue;
    final at = lastShared(option);
    if (at != null && (bestAt == null || at.isAfter(bestAt))) {
      best = o;
      bestAt = at;
    }
  }
  return best >= 0 ? best : choice.options.indexWhere(complete);
}

/// The option of choice [index] in use: the user's pick while it is
/// complete, else [defaultOption]. -1 when none is complete.
int chosenOption(
  int index,
  DisclosureChoice choice,
  DisclosureSelection s, {
  SharesOf sharesOf = _never,
}) {
  final picked = s.option[index];
  if (picked != null &&
      picked >= 0 &&
      picked < choice.options.length &&
      complete(choice.options[picked])) {
    return picked;
  }
  return defaultOption(choice, sharesOf: sharesOf);
}

/// The cards in use for [slot]: the user's usable picks that are still
/// candidates (a stale pick falls back), else [defaultCards].
List<SelectableCredentialInstance> chosenCards(
  DisclosureSlot slot,
  DisclosureSelection s, {
  SharesOf sharesOf = _never,
  Set<String> taken = const {},
}) {
  final usableCards = slot.candidates.where(usable).toList();
  final picked = [
    for (final hash in s.cards[selectionKey(slot)] ?? const <String>[])
      ?usableCards.firstWhereOrNull((c) => c.hash == hash),
  ];
  if (picked.isNotEmpty) return slot.multiple ? picked : [picked.first];
  return defaultCards(slot, sharesOf: sharesOf, taken: taken);
}

/// The selection worked out for the whole plan: per choice the option in
/// use, and per slot id the cards. A slot id that appears in two choices has
/// one set of cards (the first place it is resolved).
class Chosen {
  final DisclosurePlan plan;
  final DisclosureSelection selection;

  /// Per choice the option in use; -1 when none is complete.
  final List<int> option;

  /// Per slot id the cards in use (only for slots of options in use).
  final Map<String, List<SelectableCredentialInstance>> cards;

  const Chosen._(this.plan, this.selection, this.option, this.cards);

  /// Whether choice [i] is shared: a required one always, an optional one
  /// when switched on; and it has a complete option.
  bool shared(int i) =>
      option[i] >= 0 &&
      (!plan.choices[i].optional || selection.optionalOn.contains(i));

  /// The cards of [slot] in use.
  List<SelectableCredentialInstance> of(DisclosureSlot slot) =>
      cards[selectionKey(slot)] ?? const [];

  /// The option of choice [i] in use, or null.
  DisclosureOption? optionOf(int i) =>
      option[i] < 0 ? null : plan.choices[i].options[option[i]];
}

Chosen resolve(
  DisclosurePlan plan,
  DisclosureSelection s, {
  SharesOf sharesOf = _never,
}) {
  final options = <int>[];
  final cards = <String, List<SelectableCredentialInstance>>{};
  for (final (i, choice) in plan.choices.indexed) {
    final o = chosenOption(i, choice, s, sharesOf: sharesOf);
    options.add(o);
    if (o < 0) continue;
    final taken = <String>{};
    for (final slot in choice.options[o].slots) {
      final chosen = cards[selectionKey(slot)] ??= chosenCards(
        slot,
        s,
        sharesOf: sharesOf,
        taken: taken,
      );
      taken.addAll(chosen.map((c) => c.hash));
    }
  }
  return Chosen._(plan, s, options, cards);
}

/// What is sent to irmago when the user shares: per choice the option in use
/// and the cards per slot, each with every attribute it shows; -1 for an
/// optional choice that is not shared.
List<ChoiceSelection> answerFor(
  DisclosurePlan plan,
  DisclosureSelection s, {
  SharesOf sharesOf = _never,
}) {
  final chosen = resolve(plan, s, sharesOf: sharesOf);
  return [
    for (final (i, _) in plan.choices.indexed)
      if (!chosen.shared(i))
        ChoiceSelection.none()
      else
        ChoiceSelection(
          option: chosen.option[i],
          slots: [
            for (final slot in chosen.optionOf(i)!.slots)
              SlotSelection(
                slotId: slot.id,
                credentials: [
                  for (final card in chosen.of(slot))
                    SelectedCredential(
                      credentialId: card.credentialId,
                      credentialHash: card.hash,
                      attributePaths: [
                        for (final a in card.attributes) a.claimPath,
                      ],
                    ),
                ],
              ),
          ],
        ),
  ];
}

/// The cards that are shared (the pile, the done screen): required and
/// shared optional, each card once.
List<SelectableCredentialInstance> usedCards(
  DisclosurePlan plan,
  DisclosureSelection s, {
  SharesOf sharesOf = _never,
}) {
  final chosen = resolve(plan, s, sharesOf: sharesOf);
  final seen = <String>{};
  return [
    for (final (i, _) in plan.choices.indexed)
      if (chosen.shared(i))
        for (final slot in chosen.optionOf(i)!.slots)
          for (final card in chosen.of(slot))
            if (seen.add(card.hash)) card,
  ];
}

// --- The overview (2.2) ---------------------------------------------------------

/// One block of values on the overview: the cards whose values it lists.
/// A card without attributes is the one row "only that you have this card".
class ValueBlock {
  /// The choice it belongs to.
  final int choice;
  final List<SelectableCredentialInstance> cards;

  /// The block of a shared optional choice: its own card, with the chip.
  final bool optional;

  const ValueBlock(this.choice, this.cards, {this.optional = false});
}

/// What the overview lists: per required choice a block of the cards of its
/// option (one block per card of a multiple slot), then one block per shared
/// optional choice. A slot id used by two choices is listed once.
List<ValueBlock> overviewBlocks(
  DisclosurePlan plan,
  DisclosureSelection s, {
  SharesOf sharesOf = _never,
}) {
  final chosen = resolve(plan, s, sharesOf: sharesOf);
  final listed = <String>{};
  List<ValueBlock> blocksOf(int i, {required bool optional}) {
    final main = <SelectableCredentialInstance>[];
    final extra = <ValueBlock>[];
    for (final slot in chosen.optionOf(i)!.slots) {
      if (!listed.add(selectionKey(slot))) continue;
      if (slot.multiple) {
        for (final card in chosen.of(slot)) {
          extra.add(ValueBlock(i, [card], optional: optional));
        }
      } else {
        main.addAll(chosen.of(slot));
      }
    }
    return [
      if (main.isNotEmpty) ValueBlock(i, main, optional: optional),
      ...extra,
    ];
  }

  return [
    for (final (i, choice) in plan.choices.indexed)
      if (!choice.optional && chosen.shared(i)) ...blocksOf(i, optional: false),
    for (final (i, choice) in plan.choices.indexed)
      if (choice.optional && chosen.shared(i)) ...blocksOf(i, optional: true),
  ];
}

/// Whether anything in [plan] can change ("Wijzig" rather than "Bekijk"): a
/// choice with several options, an optional one, or a slot with more than one
/// card or a card that can be added.
bool canChangeAnything(DisclosurePlan plan) => plan.choices.any(
  (c) =>
      c.options.length > 1 ||
      c.optional ||
      c.options.any(
        (o) => o.slots.any(
          (slot) =>
              groupsOf(slot).where((g) => g.usable).length > 1 ||
              canAddAnother(slot),
        ),
      ),
);

/// The optional choices that are not shared but could be, or could be added:
/// what the hint under the pile counts (2.2). A choice that can be neither is
/// left out (2.10).
List<int> optionalHint(
  DisclosurePlan plan,
  DisclosureSelection s, {
  SharesOf sharesOf = _never,
}) {
  final chosen = resolve(plan, s, sharesOf: sharesOf);
  return [
    for (final (i, choice) in plan.choices.indexed)
      if (choice.optional &&
          !chosen.shared(i) &&
          (chosen.option[i] >= 0 || addWays(choice).isNotEmpty))
        i,
  ];
}

/// The names of the shared values the requestor declared it keeps (2.14),
/// each name once, in the order they are listed.
List<String> keptNames(
  DisclosurePlan plan,
  DisclosureSelection s, {
  SharesOf sharesOf = _never,
}) {
  final names = <String>[];
  for (final block in overviewBlocks(plan, s, sharesOf: sharesOf)) {
    for (final card in block.cards) {
      for (final a in card.attributes) {
        if (a.intentToRetain == true &&
            !names.contains(a.effectiveDisplayName)) {
          names.add(a.effectiveDisplayName);
        }
      }
    }
  }
  return names;
}

// --- Adding (2.1, 2.5.3) ---------------------------------------------------------

/// One way to answer a choice by adding cards: an option that is not
/// complete but can be completed from Yivi.
class AddWay {
  final int option;

  /// The slots it still needs, and the ones that already have a card.
  final List<DisclosureSlot> todo;
  final List<DisclosureSlot> owned;

  const AddWay(this.option, this.todo, this.owned);

  /// The problem of its first slot to do (a card that must be added again).
  CardProblem? get problem => slotProblem(todo.first);
}

/// The ways to answer [choice] by adding, nearest first ([nearestFirst]).
/// An option that cannot be completed from Yivi is not a way (2.10).
List<AddWay> addWays(DisclosureChoice choice) => nearestFirst([
  for (final (o, option) in choice.options.indexed)
    if (!complete(option) && canComplete(option))
      AddWay(o, todoSlots(option), [
        for (final slot in option.slots)
          if (slot.candidates.any(usable)) slot,
      ]),
]);

/// Ways you already hold part of first (least left to add first), then the
/// rest; request order within each group.
List<AddWay> nearestFirst(List<AddWay> ways) {
  int rank(AddWay w) => (w.owned.isNotEmpty ? 0 : 100) + w.todo.length;
  return ways.indexed
      .sortedByCompare((e) => e, (a, b) {
        final r = rank(a.$2) - rank(b.$2);
        return r != 0 ? r : a.$1 - b.$1;
      })
      .map((e) => e.$2)
      .toList();
}

/// The required choices that stop the request: no option is complete and
/// none can be completed from Yivi (2.10).
List<int> blockedChoices(DisclosurePlan plan) => [
  for (final (i, choice) in plan.choices.indexed)
    if (needsWork(choice) && addWays(choice).isEmpty) i,
];

/// A card in the app with another value than is asked (2.1): the card, the
/// attribute that differs, and what is asked of it.
class OtherValue {
  final Credential card;
  final Attribute have;
  final Attribute asked;

  const OtherValue(this.card, this.have, this.asked);
}

/// For a required choice that cannot be answered: the card in the app of a
/// kind its first way needs, with another value than is asked. irmago does
/// not send such cards as candidates, so they are found in [wallet].
OtherValue? otherValueOf(DisclosureChoice choice, List<Credential> wallet) {
  if (!needsWork(choice)) return null;
  for (final way in addWays(choice)) {
    for (final slot in way.todo) {
      if (slot.candidates.isNotEmpty) continue;
      for (final d in slot.obtainable) {
        for (final card in wallet.where(
          (c) => c.credentialId == d.credentialId,
        )) {
          for (final asked in d.attributes) {
            final allowed = allowedValues(asked);
            if (allowed.isEmpty) continue;
            final have = card.attributes.firstWhereOrNull(
              (a) => const ListEquality<dynamic>().equals(
                a.claimPath,
                asked.claimPath,
              ),
            );
            if (have == null || allowed.any((v) => sameValue(have.value, v))) {
              continue;
            }
            return OtherValue(card, have, asked);
          }
        }
      }
    }
  }
  return null;
}

/// The required choices where a card in the app has another value than is
/// asked, with what it has and what is asked.
Map<int, OtherValue> otherValueRows(
  DisclosurePlan plan,
  List<Credential> wallet,
) => {
  for (final (i, choice) in plan.choices.indexed)
    i: ?otherValueOf(choice, wallet),
};

/// The state of a row of the add step.
enum AddRowState {
  /// Answered now: "Staat nu in je app".
  done,

  /// One way to add it.
  oneWay,

  /// Several ways, each one card: "Eén is genoeg. Kies er één."
  severalCards,

  /// Several ways, some with several cards: "Kies uit drie mogelijkheden".
  severalThings,

  /// Yivi cannot add it: the request stops here (2.10).
  blocked,
}

/// One row of the add step (2.1).
class AddStepRow {
  final int choice;
  final AddRowState state;

  /// The ways to add it, nearest first; empty when done or blocked.
  final List<AddWay> ways;

  /// When done: the option now in use.
  final int? doneOption;

  /// A card that must be added again (one way), or the first way that has
  /// such a card (several ways), and that way.
  final CardProblem? problem;
  final AddWay? problemWay;

  /// A card in the app with another value than is asked.
  final OtherValue? otherValue;

  /// One way of several slots, of which some are owned: "Horen bij elkaar ·
  /// {have} van {total} in je app".
  final (int, int)? together;

  /// What is asked of the values, per attribute with allowed values (the
  /// blue tags), of the first way.
  final List<Attribute> asked;

  /// Blocked: the option it is about, its problem, and its first slot to do.
  final DisclosureSlot? blockedSlot;

  const AddStepRow({
    required this.choice,
    required this.state,
    this.ways = const [],
    this.doneOption,
    this.problem,
    this.problemWay,
    this.otherValue,
    this.together,
    this.asked = const [],
    this.blockedSlot,
  });

  bool get todo => state != AddRowState.done && state != AddRowState.blocked;
}

/// The rows of the add step: the choices that needed work when the request
/// opened ([fixed]), each with its state now; when a required choice cannot
/// be completed from Yivi, only the rows that stop the request (2.10).
List<AddStepRow> addStepRows(
  DisclosurePlan plan,
  List<int> fixed, {
  List<Credential> wallet = const [],
}) {
  final blocked = blockedChoices(plan);
  final shown = blocked.isNotEmpty ? blocked : fixed;
  return [
    for (final i in shown)
      if (i < plan.choices.length) _rowOf(plan, i, wallet),
  ];
}

AddStepRow _rowOf(DisclosurePlan plan, int i, List<Credential> wallet) {
  final choice = plan.choices[i];
  if (!needsWork(choice)) {
    return AddStepRow(
      choice: i,
      state: AddRowState.done,
      doneOption: choice.options.indexWhere(complete),
    );
  }
  final ways = addWays(choice);
  if (ways.isEmpty) {
    final slot = todoSlots(choice.options.first).firstOrNull;
    return AddStepRow(
      choice: i,
      state: AddRowState.blocked,
      problem: slot == null ? null : slotProblem(slot),
      blockedSlot: slot,
    );
  }
  final asked = [
    for (final slot in ways.first.todo)
      for (final a in addableFor(slot)?.attributes ?? const <Attribute>[])
        if (allowedValues(a).isNotEmpty) a,
  ];
  if (ways.length == 1) {
    final way = ways.single;
    final option = choice.options[way.option];
    return AddStepRow(
      choice: i,
      state: AddRowState.oneWay,
      ways: ways,
      problem: way.problem,
      problemWay: way.problem == null ? null : way,
      otherValue: otherValueOf(choice, wallet),
      together: option.slots.length > 1
          ? (option.slots.length - way.todo.length, option.slots.length)
          : null,
      asked: asked,
    );
  }
  final bad = ways.firstWhereOrNull((w) => w.problem != null);
  return AddStepRow(
    choice: i,
    state: ways.any((w) => choice.options[w.option].slots.length > 1)
        ? AddRowState.severalThings
        : AddRowState.severalCards,
    ways: ways,
    problem: bad?.problem,
    problemWay: bad,
    otherValue: otherValueOf(choice, wallet),
    asked: asked,
  );
}

/// The title of the add step.
enum AddStepTitle {
  /// "Voeg eerst een kaartje toe" ([AddStepHeader.count] == 1) / "Voeg
  /// eerst {count} kaartjes toe".
  cards,

  /// "Voeg eerst toe wat nog ontbreekt": a choice in the list has an option
  /// of several cards.
  things,

  /// "Alles is toegevoegd".
  done,

  /// "In je app staat iets anders": every row still to do has a card with
  /// another value.
  otherValue,

  /// "Dit kun je nu niet delen" (2.10).
  blocked,
}

/// What the bottom of the add step says.
enum AddStepLine {
  /// "Nog één kaartje / {count} kaartjes, dan zie je wat je deelt".
  cardsLeft,

  /// "Nog één ding / {count} dingen, …".
  thingsLeft,

  /// "Alles staat in je app".
  done,

  /// "Je deelt niets" (blocked).
  nothing,
}

/// The header and footer of the add step.
class AddStepHeader {
  final AddStepTitle title;

  /// The number of choices in the list (for [AddStepTitle.cards]).
  final int count;
  final AddStepLine line;

  /// The rows still to do (for the line).
  final int left;

  /// Whether to show the help text under the list (a row has a card with
  /// another value).
  final bool otherValueHelp;

  const AddStepHeader({
    required this.title,
    required this.count,
    required this.line,
    required this.left,
    required this.otherValueHelp,
  });
}

AddStepHeader addStepHeader(
  DisclosurePlan plan,
  List<int> fixed, {
  List<Credential> wallet = const [],
}) {
  final rows = addStepRows(plan, fixed, wallet: wallet);
  final blocked = blockedChoices(plan).isNotEmpty;
  final left = rows.where((r) => r.todo).toList();
  final other = left.where((r) => r.otherValue != null).length;
  final things = fixed.any(
    (i) => i < plan.choices.length && isBig(plan.choices[i]),
  );
  return AddStepHeader(
    title: blocked
        ? AddStepTitle.blocked
        : left.isNotEmpty && other == left.length
        ? AddStepTitle.otherValue
        : left.isEmpty
        ? AddStepTitle.done
        : things
        ? AddStepTitle.things
        : AddStepTitle.cards,
    count: fixed.length,
    line: blocked
        ? AddStepLine.nothing
        : left.isEmpty
        ? AddStepLine.done
        : things
        ? AddStepLine.thingsLeft
        : AddStepLine.cardsLeft,
    left: left.length,
    otherValueHelp: other > 0 && !blocked,
  );
}

/// What the bottom button of the add step does.
enum NextKind {
  /// "{name} toevoegen".
  add,

  /// "{name} opnieuw toevoegen": a card that is revoked or expired.
  addAgain,

  /// "{name} opnieuw ophalen": the card in the app has another value.
  fetchAgain,

  /// "Kies wat je toevoegt": several ways.
  choose,

  /// "Bekijk wat je deelt": everything is in the app.
  review,

  /// "Sluiten": the request cannot be finished (2.10).
  close,
}

class NextAction {
  final NextKind kind;

  /// The row it is for, and its way (one way).
  final int? choice;
  final AddWay? way;

  const NextAction(this.kind, {this.choice, this.way});

  /// The names of what [way] still needs, joined by the screen with " + ".
  List<String> names(DisclosurePlan plan) => [
    for (final slot in way?.todo ?? const <DisclosureSlot>[])
      addableFor(slot)?.name ?? slotName(slot),
  ];
}

/// The bottom button of the add step: the next row's action.
NextAction nextAction(
  DisclosurePlan plan,
  List<int> fixed, {
  List<Credential> wallet = const [],
}) {
  if (blockedChoices(plan).isNotEmpty) return const NextAction(NextKind.close);
  final row = addStepRows(
    plan,
    fixed,
    wallet: wallet,
  ).firstWhereOrNull((r) => r.todo);
  if (row == null) return const NextAction(NextKind.review);
  if (row.ways.length > 1) {
    return NextAction(NextKind.choose, choice: row.choice);
  }
  final way = row.ways.single;
  return NextAction(
    row.otherValue != null
        ? NextKind.fetchAgain
        : way.problem != null
        ? NextKind.addAgain
        : NextKind.add,
    choice: row.choice,
    way: way,
  );
}

/// What the blue tag of an asked value says (2.12): the name, the first
/// three allowed values, and how many more there are.
class AskedTag {
  final String name;
  final List<AttributeValue> shown;
  final int more;

  const AskedTag(this.name, this.shown, this.more);
}

AskedTag? askedTag(Attribute attribute) {
  final values = allowedValues(attribute);
  if (values.isEmpty) return null;
  return AskedTag(
    attribute.effectiveDisplayName,
    values.length <= 3 ? values : values.take(3).toList(),
    values.length <= 3 ? 0 : values.length - 3,
  );
}

/// For a card about to be added for [slot]: the offered values that are none
/// of the values asked (the warning on the offer page, 2.1).
List<(Attribute offered, Attribute asked)> offerMismatch(
  Credential offered,
  DisclosureSlot slot,
) => [
  for (final d in slot.obtainable.where(
    (d) => d.credentialId == offered.credentialId,
  ))
    for (final asked in d.attributes)
      if (allowedValues(asked) case final allowed when allowed.isNotEmpty)
        if (offered.attributes.firstWhereOrNull(
              (a) => const ListEquality<dynamic>().equals(
                a.claimPath,
                asked.claimPath,
              ),
            )
            case final got? when !allowed.any((v) => sameValue(got.value, v)))
          (got, asked),
];

// --- Kies wat je deelt (2.3, 2.4) --------------------------------------------------

/// The link under a choice, or a slot, on the change page.
enum ChangeLink {
  /// "Ander kaartje kiezen ›": a small choice with more than one kind.
  pickCard,

  /// "{Ander …} kiezen ›": one kind with more than one card, or one that can
  /// be added again.
  pickKind,

  /// "Kies welke je deelt ›": a slot that takes several cards.
  pickSeveral,

  /// "Andere combinatie kiezen ›": a big choice with more than one option,
  /// or an optional big choice.
  pickCombination,
}

/// The kinds (credential types) in play in a small [choice]: of the cards in
/// its complete options and of what can be added.
Set<String> kindsInPlay(DisclosureChoice choice) => {
  for (final option in choice.options)
    for (final slot in option.slots)
      if (slot.candidates.any(usable) || canAddAnother(slot)) slotType(slot),
};

/// Whether [slot] has something to change: more than one usable card (as
/// rows of identical cards are one), or a card that can be added again.
bool slotChangeable(DisclosureSlot slot) =>
    groupsOf(slot).where((g) => g.usable).length > 1 || canAddAnother(slot);

/// What the change page shows for a required choice, or a shared optional
/// one: the slots of the option in use and their cards, the link per slot
/// (big choice) and the link of the choice.
class ChangeCard {
  final int choice;
  final List<DisclosureSlot> slots;

  /// Per slot id its link inside a big choice, or for a multiple slot.
  final Map<String, ChangeLink> slotLinks;

  /// The link of the choice, if any.
  final ChangeLink? link;

  const ChangeCard(this.choice, this.slots, this.slotLinks, this.link);
}

/// The cards of the change page for the choices that are shared, required
/// ones and switched-on optional ones, in request order.
List<ChangeCard> changeCards(
  DisclosurePlan plan,
  DisclosureSelection s, {
  SharesOf sharesOf = _never,
}) {
  final chosen = resolve(plan, s, sharesOf: sharesOf);
  final out = <ChangeCard>[];
  for (final (i, choice) in plan.choices.indexed) {
    final option = chosen.optionOf(i);
    if (option == null || !chosen.shared(i)) continue;
    final slotLinks = <String, ChangeLink>{};
    ChangeLink? link;
    if (isBig(choice)) {
      for (final slot in option.slots) {
        if (slot.multiple) {
          slotLinks[slot.id] = ChangeLink.pickSeveral;
        } else if (slotChangeable(slot)) {
          slotLinks[slot.id] = ChangeLink.pickKind;
        }
      }
      if (choice.options.length > 1 || choice.optional) {
        link = ChangeLink.pickCombination;
      }
    } else {
      final slot = option.slots.single;
      if (slot.multiple) {
        link = ChangeLink.pickSeveral;
      } else if (kindsInPlay(choice).length > 1) {
        link = ChangeLink.pickCard;
      } else if (choice.options.any((o) => o.slots.any(slotChangeable))) {
        link = ChangeLink.pickKind;
      }
    }
    out.add(ChangeCard(i, option.slots, slotLinks, link));
  }
  return out;
}

/// The one link under an optional choice that is not shared (2.3).
enum OptionalLink {
  /// "Combinatie kiezen ›".
  chooseCombination,

  /// "Kaartje kiezen ›".
  chooseCard,

  /// "Ook delen": one option with one distinct card, shared at once.
  alsoShare,

  /// "＋ {name} toevoegen": not in the app, one way.
  addOne,

  /// "＋ Kaartje toevoegen": not in the app, several ways.
  add,
}

/// An optional choice on the change page.
class OptionalItem {
  final int choice;

  /// Shared: its card with "Niet delen" (a [ChangeCard] shows it).
  final bool shared;

  /// Not shared: the option it shows (pictures), and the link.
  final int shownOption;
  final OptionalLink? link;

  const OptionalItem(
    this.choice, {
    required this.shared,
    this.shownOption = 0,
    this.link,
  });
}

/// The link under not-shared optional choice [i].
OptionalLink? optionalLink(
  int i,
  DisclosurePlan plan,
  DisclosureSelection s, {
  SharesOf sharesOf = _never,
}) {
  final choice = plan.choices[i];
  final o = chosenOption(i, choice, s, sharesOf: sharesOf);
  if (o < 0) {
    final ways = addWays(choice);
    if (ways.isEmpty) return null;
    return ways.length == 1 ? OptionalLink.addOne : OptionalLink.add;
  }
  final plain =
      choice.options.length == 1 && choice.options.single.slots.length == 1;
  if (plain) {
    final slot = choice.options.single.slots.single;
    if (groupsOf(slot).where((g) => g.usable).length == 1) {
      return OptionalLink.alsoShare;
    }
  }
  return isBig(choice)
      ? OptionalLink.chooseCombination
      : OptionalLink.chooseCard;
}

/// The optional choices of the change page, in request order. One that can
/// be neither shared nor added is left out (2.10).
List<OptionalItem> optionalItems(
  DisclosurePlan plan,
  DisclosureSelection s, {
  SharesOf sharesOf = _never,
}) {
  final chosen = resolve(plan, s, sharesOf: sharesOf);
  final out = <OptionalItem>[];
  for (final (i, choice) in plan.choices.indexed) {
    if (!choice.optional) continue;
    if (chosen.shared(i)) {
      out.add(OptionalItem(i, shared: true));
      continue;
    }
    final link = optionalLink(i, plan, s, sharesOf: sharesOf);
    if (link == null) continue;
    final o = chosen.option[i];
    out.add(
      OptionalItem(
        i,
        shared: false,
        shownOption: o >= 0 ? o : addWays(choice).first.option,
        link: link,
      ),
    );
  }
  return out;
}

// --- Sheets (2.5) -------------------------------------------------------------

/// One row of "Welk kaartje deel je?": a group of identical cards of a slot.
class SheetRow {
  final DisclosureSlot slot;
  final int option;
  final CandidateGroup group;

  /// Whether it is the chosen one (radio filled, or ticked).
  final bool selected;

  const SheetRow(this.slot, this.option, this.group, {required this.selected});

  /// Why it cannot be picked; listed last, without a radio (2.10).
  CardProblem? get problem => problemOf(group.first);
}

/// The content of "Welk kaartje deel je?".
class WhichCardSheet {
  /// The rows: usable groups first, unusable last.
  final List<SheetRow> rows;

  /// One kind in the list: its head once, rows with values only.
  final bool oneKind;

  /// The first row is "Niet delen" (optional choice), and it is selected.
  final bool nothingRow;
  final bool nothingSelected;

  /// Rows have a radio (or a check for a multiple slot) and the sheet a
  /// "Kies" (or "Klaar") button: at least two things to pick from.
  final bool radios;

  /// Ticks instead of radios, title "Welke kaartjes deel je?".
  final bool multiple;

  /// The kinds that can be added from here ("＋ Ander … toevoegen", or "＋
  /// Ander kaartje toevoegen" when several).
  final List<DisclosureSlot> addable;

  /// The slot is used by another choice too: the "telt voor twee vragen"
  /// line (2.14).
  final bool linked;

  const WhichCardSheet({
    required this.rows,
    required this.oneKind,
    required this.nothingRow,
    required this.nothingSelected,
    required this.radios,
    required this.multiple,
    required this.addable,
    required this.linked,
  });
}

WhichCardSheet _sheet(
  DisclosurePlan plan,
  List<(int, DisclosureSlot)> slots,
  Chosen chosen, {
  required int choice,
  required bool optional,
  required bool shared,
}) {
  final rows = <SheetRow>[];
  final dead = <SheetRow>[];
  for (final (o, slot) in slots) {
    final picked = {for (final c in chosen.of(slot)) c.hash};
    final inUse = shared && chosen.option[choice] == o;
    for (final g in groupsOf(slot)) {
      final row = SheetRow(
        slot,
        o,
        g,
        selected: inUse && g.cards.any((c) => picked.contains(c.hash)),
      );
      (g.usable ? rows : dead).add(row);
    }
  }
  final multiple = slots.length == 1 && slots.single.$2.multiple;
  final pickable = rows.length + (optional ? 1 : 0);
  final ids = {for (final (_, slot) in slots) slot.id};
  final linked = plan.choices.indexed.any(
    (e) =>
        e.$1 != choice &&
        e.$2.options.any((o) => o.slots.any((s) => ids.contains(s.id))),
  );
  return WhichCardSheet(
    rows: [...rows, ...dead],
    oneKind: {for (final (_, slot) in slots) slotType(slot)}.length == 1,
    nothingRow: optional,
    nothingSelected: optional && !shared,
    radios: multiple || pickable >= 2,
    multiple: multiple,
    addable: [
      for (final (_, slot) in slots)
        if (canAddAnother(slot)) slot,
    ],
    linked: linked,
  );
}

/// "Welk kaartje deel je?" for small choice [i]: the cards of all its
/// options, one selection.
WhichCardSheet sheetRowsForChoice(
  int i,
  DisclosurePlan plan,
  DisclosureSelection s, {
  SharesOf sharesOf = _never,
}) {
  final choice = plan.choices[i];
  final chosen = resolve(plan, s, sharesOf: sharesOf);
  return _sheet(
    plan,
    [
      for (final (o, option) in choice.options.indexed)
        if (option.slots.length == 1) (o, option.slots.single),
    ],
    chosen,
    choice: i,
    optional: choice.optional,
    shared: chosen.shared(i),
  );
}

/// "Welk kaartje deel je?" for one slot of the option in use of choice [i]
/// (a slot inside a big choice, or a multiple slot).
WhichCardSheet sheetRowsForSlot(
  int i,
  DisclosureSlot slot,
  DisclosurePlan plan,
  DisclosureSelection s, {
  SharesOf sharesOf = _never,
}) {
  final chosen = resolve(plan, s, sharesOf: sharesOf);
  return _sheet(
    plan,
    [(chosen.option[i], slot)],
    chosen,
    choice: i,
    optional: false,
    shared: true,
  );
}

/// One block of "Welke combinatie deel je?".
class CombinationBlock {
  final int option;

  /// Every slot has a usable card.
  final bool complete;

  /// The chosen one.
  final bool selected;

  /// Not complete: the slots still to add ("Nog toevoegen: {names}").
  final List<DisclosureSlot> missing;

  const CombinationBlock(
    this.option, {
    required this.complete,
    required this.selected,
    this.missing = const [],
  });
}

/// The content of "Welke combinatie deel je?".
class CombinationSheet {
  final List<CombinationBlock> blocks;
  final bool nothingRow;
  final bool nothingSelected;

  /// A "Kies" button: at least two blocks with a radio.
  final bool choose;

  const CombinationSheet(
    this.blocks, {
    required this.nothingRow,
    required this.nothingSelected,
    required this.choose,
  });
}

/// The options of choice [i]: complete first, then the ones that can still
/// be completed from Yivi; request order within each group. An option that
/// cannot be completed from Yivi is left out (2.10).
CombinationSheet combinationBlocks(
  int i,
  DisclosurePlan plan,
  DisclosureSelection s, {
  SharesOf sharesOf = _never,
}) {
  final choice = plan.choices[i];
  final chosen = resolve(plan, s, sharesOf: sharesOf);
  final shared = chosen.shared(i);
  final done = <CombinationBlock>[];
  final todo = <CombinationBlock>[];
  for (final (o, option) in choice.options.indexed) {
    if (complete(option)) {
      done.add(
        CombinationBlock(
          o,
          complete: true,
          selected: shared && chosen.option[i] == o,
        ),
      );
    } else if (canComplete(option)) {
      todo.add(
        CombinationBlock(
          o,
          complete: false,
          selected: false,
          missing: todoSlots(option),
        ),
      );
    }
  }
  final pickable = done.length + (choice.optional ? 1 : 0);
  return CombinationSheet(
    [...done, ...todo],
    nothingRow: choice.optional,
    nothingSelected: choice.optional && !shared,
    choose: pickable >= 2,
  );
}

// --- Values -------------------------------------------------------------------

/// What the required choices that cannot be answered yet offer to add: per
/// slot without a usable card, its descriptors.
List<CredentialDescriptor> missingDescriptors(DisclosurePlan? plan) => [
  for (final choice in plan?.choices ?? const <DisclosureChoice>[])
    if (needsWork(choice))
      for (final option in choice.options)
        for (final slot in option.slots)
          if (!slot.candidates.any(usable)) ...slot.obtainable,
];

/// The values [attribute] may have for the request: [Attribute.requestedValues],
/// or the one [Attribute.requestedValue] when the list is empty. Only values
/// that say something (a type alone asks for any value).
List<AttributeValue> allowedValues(Attribute attribute) => [
  for (final v
      in attribute.requestedValues.isNotEmpty
          ? attribute.requestedValues
          : [?attribute.requestedValue])
    if (v.hasConcreteValue) v,
];

/// The card picture of [instance]: the wallet card with the same hash
/// (which carries the issuer's design), or one built from the instance.
Credential sharedCardFor(
  SelectableCredentialInstance instance,
  List<Credential> wallet,
) =>
    wallet.firstWhereOrNull((c) => c.hash == instance.hash) ??
    Credential(
      credentialId: instance.credentialId,
      hash: instance.hash,
      name: instance.name,
      issuer: instance.issuer,
      image: instance.image,
      credentialInstanceIds: {instance.format: instance.hash},
      batchInstanceCountsRemaining: {
        instance.format: instance.batchInstanceCountRemaining,
      },
      attributes: instance.attributes,
      revoked: instance.revoked,
      revocationSupported: instance.revocationSupported,
      issueUrl: instance.issueUrl,
      issuanceDate: instance.issuanceDate,
      expiryDate: instance.expiryDate,
      isSingleton: instance.isSingleton,
    );

/// The host of [url] without "www.", as shown under an option ("on
/// privacybydesign.foundation") and on its button ("Opens …"). Null when
/// there is no usable URL.
String? hostOf(String? url) {
  if (url == null || url.isEmpty) return null;
  final host = Uri.tryParse(url)?.host;
  if (host == null || host.isEmpty) return null;
  return host.withoutWww();
}

/// [name] for use inside a sentence ("Which email address?"): the first
/// letter lowercased when it is an ordinary capitalised word, but kept for
/// abbreviations and brand names such as "ID card", "iDIN" or "BSN", and
/// in German, where nouns keep their capital.
String inSentence(String name, {String? language}) {
  if (language == "de" || name.length < 2) return name;
  final first = name[0];
  final second = name[1];
  final ordinary =
      first != first.toLowerCase() && second == second.toLowerCase();
  return ordinary ? first.toLowerCase() + name.substring(1) : name;
}

/// Whether [a] holds the same value as [b] (type and content).
bool sameValue(AttributeValue? a, AttributeValue b) =>
    a != null &&
    a.type == b.type &&
    a.string == b.string &&
    a.intValue == b.intValue &&
    a.boolValue == b.boolValue &&
    a.imagePath == b.imagePath &&
    a.base64Image == b.base64Image;

/// Whether [a] and [b] are the same party: by id, or by name when neither
/// has one (an OpenID4VP verifier without a registration).
bool sameParty(TrustedParty? a, TrustedParty b) {
  if (a == null) return false;
  if (a.id.isNotEmpty || b.id.isNotEmpty) return a.id == b.id;
  return a.name.trim().toLowerCase() == b.name.trim().toLowerCase();
}

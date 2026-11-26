import "package:collection/collection.dart";

import "../../../models/credential.dart";
import "../../../models/credential_store.dart";
import "../../../models/session_state.dart";
import "../../../models/session_user_interaction.dart";
import "../../../util/string.dart";

// What the disclosure screens show, worked out from the plan irmago sends
// (choices → options → slots → candidates) and the user's own selection only.
// Pure functions, so every rule can be unit tested without pumping a screen.

/// What the user picked in a request. Absent entries fall back to the
/// defaults.
class DisclosureSelection {
  /// Choice index → option index.
  final Map<int, int> option;

  /// Slot id → the hashes of the chosen cards. Keyed by slot id alone, so a
  /// DCQL query in several options or credential sets is one selection.
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

/// Whether [candidate] can be shared for this request: irmago's verdict,
/// never derived in the app from dates or flags.
bool usable(SelectableCredentialInstance candidate) => candidate.usable;

/// Whether every slot of [option] has a usable card.
bool complete(DisclosureOption option) =>
    option.slots.every((slot) => slot.candidates.any(usable));

/// Whether [choice] is required and cannot be answered yet.
bool needsWork(DisclosureChoice choice) =>
    !choice.optional && !choice.options.any(complete);

/// Whether every required choice of [plan] can be answered.
bool canShare(DisclosurePlan plan) => !plan.choices.any(needsWork);

/// The option of choice [index] in use: the user's pick while it can be
/// shared, else the first option that can. -1 when none can.
int chosenOption(int index, DisclosureChoice choice, DisclosureSelection s) {
  final picked = s.option[index];
  if (picked != null &&
      picked >= 0 &&
      picked < choice.options.length &&
      complete(choice.options[picked])) {
    return picked;
  }
  return choice.options.indexWhere(complete);
}

/// The cards in use for [slot]: the user's usable picks that are still
/// candidates, else the first usable card (all usable cards for a multiple
/// slot).
List<SelectableCredentialInstance> chosenCards(
  DisclosureSlot slot,
  DisclosureSelection s,
) {
  final usableCards = slot.candidates.where(usable).toList();
  final picked = [
    for (final hash in s.cards[slot.id] ?? const <String>[])
      ?usableCards.firstWhereOrNull((c) => c.hash == hash),
  ];
  if (picked.isNotEmpty) return slot.multiple ? picked : [picked.first];
  if (usableCards.isEmpty) return const [];
  return slot.multiple ? usableCards : [usableCards.first];
}

/// Whether choice [index] is shared: a required one always, an optional one
/// when the user switched it on and it can be answered.
bool choiceShared(int index, DisclosureChoice choice, DisclosureSelection s) =>
    (!choice.optional || s.optionalOn.contains(index)) &&
    chosenOption(index, choice, s) >= 0;

/// What is sent to irmago when the user shares: per choice the option in use
/// and the cards per slot, each with every attribute it shows; -1 for an
/// optional choice that is not shared.
List<ChoiceSelection> answerFor(DisclosurePlan plan, DisclosureSelection s) => [
  for (final (i, choice) in plan.choices.indexed)
    if (!choiceShared(i, choice, s))
      ChoiceSelection.none()
    else
      ChoiceSelection(
        option: chosenOption(i, choice, s),
        slots: [
          for (final slot in choice.options[chosenOption(i, choice, s)].slots)
            SlotSelection(
              slotId: slot.id,
              credentials: [
                for (final card in chosenCards(slot, s))
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

/// The cards that are shared with [s], each once (a slot named by two
/// choices, or one card in two slots, counts once).
List<SelectableCredentialInstance> sharedCards(
  DisclosurePlan plan,
  DisclosureSelection s,
) {
  final seen = <String>{};
  return [
    for (final (i, choice) in plan.choices.indexed)
      if (choiceShared(i, choice, s))
        for (final slot in choice.options[chosenOption(i, choice, s)].slots)
          for (final card in chosenCards(slot, s))
            if (seen.add(card.hash)) card,
  ];
}

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

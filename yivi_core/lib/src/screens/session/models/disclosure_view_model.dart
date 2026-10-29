import "package:collection/collection.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../models/schemaless/session_user_interaction.dart";
import "../../../widgets/credential_card/models/credential_card_status.dart";

// What the disclosure screens show, worked out from the session state irmago
// sends and the user's own selection only. Pure functions, so every rule of
// the design can be unit tested without pumping a screen.

/// Why a card cannot be shared right now: a chip on the card, and the share
/// button does the fix first.
enum CardProblem { revoked, expired }

/// The problem of [instance], if any. Revoked wins over expired. A card that
/// was shared as often as it can be (used up) counts as expired: to the
/// user it is a card that has run out.
CardProblem? problemOf(SelectableCredentialInstance instance) {
  final status = _statusOf(instance);
  if (instance.revoked) return CardProblem.revoked;
  if (status.instanceExpireState == ExpireState.expired ||
      status.timeExpireState == ExpireState.expired) {
    return CardProblem.expired;
  }
  return null;
}

/// The first problem of any card in [bundle].
CardProblem? problemOfBundle(DisclosureBundle bundle) =>
    bundle.credentials.map(problemOf).nonNulls.firstOrNull;

CredentialCardStatus _statusOf(SelectableCredentialInstance instance) =>
    CredentialCardStatus(
      expiryDateUnix: instance.expiryDate,
      revoked: instance.revoked,
      batchInstanceCountsRemaining: {
        instance.format: instance.batchInstanceCountRemaining,
      },
    );

/// The host of [url] without "www.", as shown under an option ("on
/// privacybydesign.foundation") and on its button ("Opens …"). Null when
/// there is no usable URL.
String? hostOf(String? url) {
  if (url == null || url.isEmpty) return null;
  final host = Uri.tryParse(url)?.host;
  if (host == null || host.isEmpty) return null;
  return host.startsWith("www.") ? host.substring(4) : host;
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

/// Whether Yivi can send the user to get [descriptor]: it has an issue URL.
/// Types without one (OID4VCI, mdoc, some IRMA demo types) are shown, but
/// cannot be picked.
bool canBeAdded(CredentialDescriptor descriptor) =>
    hostOf(descriptor.issueURL) != null;

/// The options of [pickOne] that can be added from Yivi, in irmago's order.
List<CredentialDescriptor> addableOptions(DisclosurePickOne pickOne) =>
    (pickOne.obtainableOptions ?? const []).where(canBeAdded).toList();

/// The options of [pickOne] that can be completed from Yivi, in irmago's
/// order: what is missing of each (all of it can be added) and what of it
/// is in the app already. One type each from an irmago that does not send
/// [DisclosurePickOne.obtainableBundles].
List<ObtainableBundle> addableBundles(DisclosurePickOne pickOne) {
  final bundles = pickOne.obtainableBundles;
  if (bundles == null) {
    return [
      for (final d in addableOptions(pickOne))
        ObtainableBundle(owned: const [], missing: [d]),
    ];
  }
  return [
    for (final b in bundles)
      if (b.missing.isNotEmpty && b.missing.every(canBeAdded)) b,
  ];
}

/// The owned option shown for [pickOne] when the user has not picked one:
/// the first that can be shared, in irmago's order (#657 puts the best one
/// first), and only when none can, the first. Optional data starts left
/// out (-1).
int defaultSelection(DisclosurePickOne pickOne) {
  if (pickOne.optional) return -1;
  final owned = pickOne.ownedOptions ?? const <DisclosureBundle>[];
  if (owned.isEmpty) return -1;
  final usable = owned.indexWhere((b) => problemOfBundle(b) == null);
  return usable < 0 ? 0 : usable;
}

/// The selected owned option of [pickOne]: [selected] when it is still a
/// valid index (the plan can change under it), otherwise the default.
int selectionOf(DisclosurePickOne pickOne, int? selected) {
  final owned = pickOne.ownedOptions ?? const [];
  if (selected != null && selected >= -1 && selected < owned.length) {
    if (selected == -1 && !pickOne.optional) return defaultSelection(pickOne);
    return selected;
  }
  return defaultSelection(pickOne);
}

/// The owned option index per pick-one, from what the user picked
/// ([chosen] holds a bundle per pick-one, [addedOptional] the optional ones
/// they included). A bundle is matched by its set of credential hashes, so
/// the choice survives the plan being sent again. Optional data that was
/// not included is -1.
Map<int, int> selectionsFrom(
  List<DisclosurePickOne> pickOnes,
  Map<int, DisclosureBundle> chosen,
  Set<int> addedOptional,
) {
  final out = <int, int>{};
  for (final (i, pickOne) in pickOnes.indexed) {
    final owned = pickOne.ownedOptions ?? const [];
    if (pickOne.optional && !addedOptional.contains(i)) {
      out[i] = -1;
      continue;
    }
    final want = chosen[i]?.credentialHashes;
    final k = want == null
        ? -1
        : owned.indexWhere((b) {
            final have = b.credentialHashes;
            return have.length == want.length && have.containsAll(want);
          });
    out[i] = k >= 0 ? k : defaultSelection(pickOne);
  }
  return out;
}

/// What is sent to irmago when the user shares: per pick-one, the selected
/// cards with the requested attribute paths, or nothing.
List<DisclosureDisconSelection> disclosureChoicesFor(
  List<DisclosurePickOne> pickOnes,
  Map<int, int> selections,
) => [
  for (final (i, pickOne) in pickOnes.indexed)
    DisclosureDisconSelection(
      credentials: switch (selectionOf(pickOne, selections[i])) {
        < 0 => const [],
        final k => [
          for (final c in pickOne.ownedOptions![k].credentials)
            SelectedCredential(
              credentialId: c.credentialId,
              credentialHash: c.hash,
              attributePaths: [for (final a in c.attributes) a.claimPath],
            ),
        ],
      },
    ),
];

/// Whether [pickOne] is an empty spot on the share screen: required, and
/// nothing in the app fills it yet (irmago sends the choices from the start,
/// with no owned options for a card that is still to be added).
bool isEmptySpot(DisclosurePickOne pickOne) =>
    !pickOne.optional && (pickOne.ownedOptions ?? const []).isEmpty;

/// [items] as one list in a sentence: "a, b or c", with [or] (" or ")
/// before the last item and commas between the others.
String orList(List<String> items, String or) => switch (items.length) {
  0 => "",
  1 => items.single,
  _ => "${items.sublist(0, items.length - 1).join(", ")}$or${items.last}",
};

/// What an empty spot asks for: its types, "Passport, ID card or Driving
/// licence", or "Root + Name" when they are only accepted [together].
/// [inList] writes every type after the first as it reads inside the list
/// ("Passport, ID card or driving licence").
String spotName(
  DisclosurePickOne pickOne,
  String or, {
  bool together = false,
  String Function(String name)? inList,
}) {
  final names = [
    for (final (n, d) in (pickOne.obtainableOptions ?? const []).indexed)
      n == 0 || inList == null ? d.name : inList(d.name),
  ];
  return together ? names.join(" + ") : orList(names, or);
}

/// What the strip under a card offers besides it: another card in the app
/// ("You can also choose another card"), or else adding one ("You can also
/// add another card"). The strip names no cards: the sheet shows them.
enum AlsoChoice { choose, add }

/// [AlsoChoice] for [pickOne] with owned option [selected] in use; null when
/// there is nothing else.
AlsoChoice? alsoChoice(DisclosurePickOne pickOne, int selected) {
  final owned = pickOne.ownedOptions ?? const <DisclosureBundle>[];
  for (final (k, b) in owned.indexed) {
    if (k != selected && problemOfBundle(b) == null) return AlsoChoice.choose;
  }
  return addableOptions(pickOne).isEmpty ? null : AlsoChoice.add;
}

/// The kinds of card optional [pickOne] takes, by their names, to say what
/// it is ("Passport, Driving licence or ID card"): those in the app first,
/// then those that can be added, each once. Only names: which values each
/// kind holds differs, so the sentence never lists them.
List<String> optionalKinds(DisclosurePickOne pickOne) {
  final out = <String>[];
  void add(String name) {
    if (name.isNotEmpty && !out.contains(name)) out.add(name);
  }

  for (final b in pickOne.ownedOptions ?? const <DisclosureBundle>[]) {
    add(b.credentials.map((c) => c.name).join(" + "));
  }
  for (final d in pickOne.obtainableOptions ?? const <CredentialDescriptor>[]) {
    add(d.name);
  }
  return out;
}

/// [items] as one list in a sentence: "a, b and c", with [and] (" and ")
/// before the last item.
String andList(List<String> items, String and) => orList(items, and);

/// Whether [pickOne]'s types are only accepted together: the missing-data
/// steps offer exactly these types as one option, a set of cards.
bool spotTogether(DisclosurePickOne pickOne, IssueDuringDisclosure? plan) {
  final ids = {
    for (final d in pickOne.obtainableOptions ?? const <CredentialDescriptor>[])
      d.credentialId,
  };
  if (ids.length < 2 || plan == null) return false;
  return plan.steps.any(
    (s) =>
        s.options.length == 1 &&
        const SetEquality<String>().equals(
          s.options.single.credentials.map((c) => c.credentialId).toSet(),
          ids,
        ),
  );
}

/// The values the request needs on the card for [pickOne] ("must be …"), as
/// field and value.
List<(String, AttributeValue)> spotRequiredValues(
  DisclosurePickOne pickOne,
) => [
  for (final d in pickOne.obtainableOptions ?? const <CredentialDescriptor>[])
    for (final a in d.attributes)
      if (a.requestedValue case final v? when v.hasConcreteValue)
        (a.effectiveDisplayName, v),
];

/// Whether the card selected for [pickOne] was added during this request.
bool addedDuringRequest(
  DisclosurePickOne pickOne,
  DisclosureBundle bundle,
  IssueDuringDisclosure? plan,
) {
  final issued = plan?.issuedCredentialIds?.keys.toSet() ?? const {};
  return !pickOne.optional &&
      bundle.credentials.any((c) => issued.contains(c.credentialId));
}

/// Whether the share screen shows "Change" on [pickOne]: there is more
/// than one thing to choose from (cards in the app plus types that can be
/// added).
bool canChange(DisclosurePickOne pickOne) =>
    (pickOne.ownedOptions ?? const []).length + addableOptions(pickOne).length >
    1;

/// The type to add to replace [bundle] when it has a problem: an addable
/// option of the same credential type, or else the problem card's own
/// issuer (irmago offers no other option for a type the user can hold only
/// one of, such as a revoked BSN). Null when it cannot be renewed from Yivi.
CredentialDescriptor? fixFor(
  DisclosurePickOne pickOne,
  DisclosureBundle bundle,
) {
  final ids = bundle.credentials.map((c) => c.credentialId).toSet();
  final offered = addableOptions(
    pickOne,
  ).firstWhereOrNull((d) => ids.contains(d.credentialId));
  if (offered != null) return offered;
  final card = bundle.credentials.firstWhereOrNull(
    (c) => problemOf(c) != null && hostOf(c.issueUrl) != null,
  );
  return card == null
      ? null
      : CredentialDescriptor(
          credentialId: card.credentialId,
          name: card.name,
          issuer: card.issuer,
          category: null,
          attributes: const [],
          issueURL: card.issueUrl,
          isSingleton: card.isSingleton,
        );
}

/// What the share button says when it shares.
enum ShareLabel { share, signAndShare, shareAndAdd, shareWithoutData, close }

/// What the button does before it can share: the next thing to add or fix.
enum NextKind {
  /// "{name} toevoegen": adds [NextStep.descriptor].
  add,

  /// "{name} opnieuw toevoegen": a new one for a card that can't be used.
  addAgain,

  /// "{name} opnieuw ophalen": a card the app holds only one of; the new
  /// one replaces it.
  fetchAgain,

  /// "Kies wat je toevoegt": several kinds to choose from.
  pick,

  /// "Allebei toevoegen": a set of cards only accepted together.
  addBoth,
}

/// The next step of the share button, for pick-one [index].
class NextStep {
  final int index;
  final NextKind kind;

  /// What [NextKind.add], [NextKind.addAgain] and [NextKind.fetchAgain] add.
  final CredentialDescriptor? descriptor;

  const NextStep(this.index, this.kind, [this.descriptor]);
}

/// A card in the app of a kind a required item takes, that is not offered
/// because one of its values is not what the request needs ("Your address
/// says Utrecht; they ask for Rijnstad"). Only when the values demonstrably
/// differ: a card that fails for another reason is not named.
class WalletMismatch {
  final Credential card;

  /// The type to get again, as the request describes it.
  final CredentialDescriptor descriptor;
  final String attributeName;
  final AttributeValue? have;
  final AttributeValue asked;

  const WalletMismatch({
    required this.card,
    required this.descriptor,
    required this.attributeName,
    required this.have,
    required this.asked,
  });
}

/// The [WalletMismatch] of empty spot [pickOne] in [wallet], if any: the
/// first card of one of its kinds with a value that differs from a concrete
/// requested value.
WalletMismatch? walletMismatch(
  DisclosurePickOne pickOne,
  List<Credential> wallet,
) {
  if (!isEmptySpot(pickOne)) return null;
  // Only a kind she can get again in Yivi: otherwise the spot says where to
  // get it.
  for (final d in addableOptions(pickOne)) {
    for (final card in wallet) {
      if (card.credentialId != d.credentialId) continue;
      for (final wanted in d.attributes) {
        final asked = wanted.requestedValue;
        if (asked == null || !asked.hasConcreteValue) continue;
        final got = card.attributes.firstWhereOrNull(
          (a) => const ListEquality<dynamic>().equals(
            a.claimPath,
            wanted.claimPath,
          ),
        );
        if (got?.value == null || sameValue(got!.value, asked)) continue;
        return WalletMismatch(
          card: card,
          descriptor: d,
          attributeName: wanted.effectiveDisplayName,
          have: got.value,
          asked: asked,
        );
      }
    }
  }
  return null;
}

/// The share button: what it says, and what it does first while it can't
/// share yet ([next]). It never sits there disabled while something can be
/// done in Yivi.
class ShareButtonState {
  final ShareLabel label;

  /// It shares when pressed: nothing is missing or blocked.
  final bool enabled;

  /// What it does instead while something is missing or can't be used.
  final NextStep? next;

  /// The problem of a selected card that blocks sharing, and that card.
  final CardProblem? blockedBy;
  final DisclosureBundle? blockedCard;

  /// Set when a required card has a problem it cannot get out of in Yivi:
  /// the button closes the session, with "Ask {issuer} for a new one."
  final String? cannotRenewFrom;

  /// The first empty spot that can be added from Yivi.
  final DisclosurePickOne? missing;

  /// An empty spot nothing can be added for from Yivi: the button closes
  /// the session, with "Get it from {issuer} first."
  final DisclosurePickOne? cannotAdd;

  /// The card in the app that does not count for the first empty spot.
  final WalletMismatch? mismatch;

  /// How many required items still need adding or fixing ("Nog 2 dingen
  /// toevoegen"), and per required item whether it is ready (the dots).
  final int toDo;
  final List<bool> ready;

  const ShareButtonState({
    required this.label,
    required this.enabled,
    this.next,
    this.blockedBy,
    this.blockedCard,
    this.cannotRenewFrom,
    this.missing,
    this.cannotAdd,
    this.mismatch,
    this.toDo = 0,
    this.ready = const [],
  });
}

/// The next step for empty spot [i] ([pickOne]): add its one kind, choose
/// between its kinds, or add a set; with a card in the app that does not
/// count ([mismatch]), get that kind again.
NextStep _nextForSpot(
  int i,
  DisclosurePickOne pickOne,
  IssueDuringDisclosure? plan,
  WalletMismatch? mismatch,
) {
  if (mismatch != null) {
    final d = mismatch.descriptor;
    return NextStep(
      i,
      d.isSingleton || mismatch.card.isSingleton
          ? NextKind.fetchAgain
          : NextKind.add,
      d,
    );
  }
  if (spotTogether(pickOne, plan)) return NextStep(i, NextKind.addBoth);
  final addable = addableOptions(pickOne);
  return addable.length == 1
      ? NextStep(i, NextKind.add, addable.single)
      : NextStep(i, NextKind.pick);
}

/// The share button for [state], with [selections] holding the user's pick
/// per pick-one index (missing entries use [defaultSelection]). [wallet]
/// finds a card in the app that does not count for an empty spot.
ShareButtonState shareButton(
  SessionState state,
  Map<int, int> selections, {
  List<Credential> wallet = const [],
}) {
  final pickOnes = state.disclosurePlan?.disclosureChoicesOverview ?? const [];
  final plan = state.disclosurePlan?.issueDuringDisclosure;
  CardProblem? blockedBy;
  DisclosureBundle? blockedCard;
  String? cannotRenewFrom;
  DisclosurePickOne? missing;
  DisclosurePickOne? cannotAdd;
  WalletMismatch? mismatch;
  NextStep? next;
  var anyShared = false;
  var toDo = 0;
  final ready = <bool>[];

  for (final (i, pickOne) in pickOnes.indexed) {
    if (isEmptySpot(pickOne)) {
      ready.add(false);
      if (addableOptions(pickOne).isEmpty) {
        cannotAdd ??= pickOne;
      } else {
        toDo++;
        if (missing == null) {
          missing = pickOne;
          mismatch = walletMismatch(pickOne, wallet);
          next ??= _nextForSpot(i, pickOne, plan, mismatch);
        }
      }
      continue;
    }
    final k = selectionOf(pickOne, selections[i]);
    if (k < 0) {
      if (!pickOne.optional) ready.add(false);
      continue;
    }
    anyShared = true;
    final bundle = pickOne.ownedOptions![k];
    final problem = problemOfBundle(bundle);
    if (pickOne.optional) continue;
    ready.add(problem == null);
    if (problem == null) continue;
    toDo++;
    blockedCard ??= bundle;
    blockedBy ??= problem;
    final fix = fixFor(pickOne, bundle);
    final kinds = addableOptions(pickOne);
    if (fix == null && kinds.isEmpty) {
      cannotRenewFrom ??= bundle.credentials.first.issuer.name;
      continue;
    }
    // One kind: a new one of it straight away. More: choose, because the
    // app doesn't know why the card stopped or whether a new one of the
    // same kind will do.
    next ??= kinds.length > 1
        ? NextStep(i, NextKind.pick)
        : NextStep(
            i,
            fix!.isSingleton || bundle.credentials.any((c) => c.isSingleton)
                ? NextKind.fetchAgain
                : NextKind.addAgain,
            fix,
          );
  }

  if (cannotAdd != null) {
    return ShareButtonState(
      label: ShareLabel.close,
      enabled: true,
      cannotAdd: cannotAdd,
      ready: ready,
    );
  }
  if (cannotRenewFrom != null) {
    return ShareButtonState(
      label: ShareLabel.close,
      enabled: true,
      blockedBy: blockedBy,
      blockedCard: blockedCard,
      cannotRenewFrom: cannotRenewFrom,
      ready: ready,
    );
  }
  final label = state.type == SessionType.signature
      ? ShareLabel.signAndShare
      : (state.offeredCredentials?.isNotEmpty ?? false)
      ? ShareLabel.shareAndAdd
      // A card still to add or renew: it will be shared once it is there.
      : anyShared || missing != null || blockedBy != null
      ? ShareLabel.share
      : ShareLabel.shareWithoutData;
  return ShareButtonState(
    label: label,
    enabled: blockedBy == null && missing == null,
    next: next,
    blockedBy: blockedBy,
    blockedCard: blockedCard,
    missing: missing,
    mismatch: mismatch,
    toDo: toDo,
    ready: ready,
  );
}

// --- The issuance permission inside a request -------------------------------

/// A value on an offered card that does not satisfy the request waiting
/// underneath: shown in red, with a note before the user adds the card.
class IssuanceMismatch {
  final String credentialId;
  final List<dynamic> claimPath;
  final String attributeName;
  final AttributeValue? offered;
  final AttributeValue required;

  const IssuanceMismatch({
    required this.credentialId,
    required this.claimPath,
    required this.attributeName,
    required this.offered,
    required this.required,
  });
}

/// The values of [offered] that differ from a `requested_value` in the
/// missing-data [steps] of the request waiting underneath.
List<IssuanceMismatch> issuanceMismatches(
  List<Credential> offered,
  List<IssuanceStep> steps,
) {
  final out = <IssuanceMismatch>[];
  for (final card in offered) {
    final templates = [
      for (final step in steps)
        for (final bundle in step.options)
          for (final d in bundle.credentials)
            if (d.credentialId == card.credentialId) d,
    ];
    for (final template in templates) {
      for (final wanted in template.attributes) {
        final requiredValue = wanted.requestedValue;
        if (requiredValue == null || !requiredValue.hasConcreteValue) continue;
        final got = card.attributes.firstWhereOrNull(
          (a) => const ListEquality<dynamic>().equals(
            a.claimPath,
            wanted.claimPath,
          ),
        );
        if (sameValue(got?.value, requiredValue)) continue;
        out.add(
          IssuanceMismatch(
            credentialId: card.credentialId,
            claimPath: wanted.claimPath,
            attributeName: wanted.effectiveDisplayName,
            offered: got?.value,
            required: requiredValue,
          ),
        );
      }
    }
  }
  return out;
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

/// "For {requestor} · step 2 of 3" context of an issuance inside a request:
/// the 1-based step of [steps] that [offered] belongs to, or null when it
/// belongs to none (or there is only one step, which needs no number).
int? stepNumberFor(List<Credential> offered, List<IssuanceStep> steps) {
  if (steps.length < 2) return null;
  final ids = offered.map((c) => c.credentialId).toSet();
  final i = steps.indexWhere(
    (s) => s.options.any(
      (b) => b.credentials.any((d) => ids.contains(d.credentialId)),
    ),
  );
  return i < 0 ? null : i + 1;
}

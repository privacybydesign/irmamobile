import "package:collection/collection.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../models/schemaless/session_user_interaction.dart";
import "../../../widgets/credential_card/models/credential_card_status.dart";

// What the disclosure screens show, worked out from the session state irmago
// sends and the user's own selection only. Pure functions, so every rule of
// the design can be unit tested without pumping a screen.

/// Why a card cannot be shared right now. Shown as a red chip on the card,
/// and the share button stays disabled while a selected card has one.
enum CardProblem { revoked, usedUp, expired }

/// The problem of [instance], if any. Revoked wins over used up, which
/// wins over expired.
CardProblem? problemOf(SelectableCredentialInstance instance) {
  final status = _statusOf(instance);
  if (instance.revoked) return CardProblem.revoked;
  if (status.instanceExpireState == ExpireState.expired) {
    return CardProblem.usedUp;
  }
  if (status.timeExpireState == ExpireState.expired) {
    return CardProblem.expired;
  }
  return null;
}

/// The first problem of any card in [bundle].
CardProblem? problemOfBundle(DisclosureBundle bundle) =>
    bundle.credentials.map(problemOf).nonNulls.firstOrNull;

/// The card can be shared once more, and then no longer: a warning chip,
/// not a problem.
bool isLastUse(SelectableCredentialInstance instance) =>
    problemOf(instance) == null && instance.batchInstanceCountRemaining == 1;

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
/// the first, in irmago's order (#657 puts the best one first). Optional
/// data starts left out (-1).
int defaultSelection(DisclosurePickOne pickOne) {
  if (pickOne.optional) return -1;
  return (pickOne.ownedOptions ?? const []).isEmpty ? -1 : 0;
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
    out[i] = k >= 0 ? k : (owned.isEmpty ? -1 : 0);
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

/// How the share screen names another choice for a pick-one, in "You can
/// also choose …".
enum AlsoKind {
  /// Another card of the type that is selected now: "your other …".
  other,

  /// A type the user has exactly one card of: "your …".
  your,

  /// A type the user has none or several of: "a …".
  a,
}

/// The other choices for [pickOne] next to the selected owned option
/// [selected], for "You can also choose your other email address or a
/// mobile number": the name of each and how to say it, without repeats, in
/// the order of the cards in the app and then the types that can be added.
List<(AlsoKind, String)> alsoChoose(DisclosurePickOne pickOne, int selected) {
  final owned = pickOne.ownedOptions ?? const <DisclosureBundle>[];
  String idOf(DisclosureBundle b) =>
      b.credentials.map((c) => c.credentialId).join("+");
  String nameOf(DisclosureBundle b) =>
      b.credentials.map((c) => c.name).join(" + ");
  final current = selected >= 0 && selected < owned.length
      ? idOf(owned[selected])
      : null;
  int ownedOf(String id) => owned.where((b) => idOf(b) == id).length;

  final out = <(AlsoKind, String)>[];
  void add(AlsoKind kind, String name) {
    if (!out.contains((kind, name))) out.add((kind, name));
  }

  for (final (k, b) in owned.indexed) {
    if (k == selected) continue;
    final id = idOf(b);
    add(
      id == current
          ? AlsoKind.other
          : ownedOf(id) == 1
          ? AlsoKind.your
          : AlsoKind.a,
      nameOf(b),
    );
  }
  for (final d in addableOptions(pickOne)) {
    add(
      d.credentialId == current
          ? AlsoKind.other
          : ownedOf(d.credentialId) == 1
          ? AlsoKind.your
          : AlsoKind.a,
      d.name,
    );
  }
  return out;
}

/// What optional [pickOne] asks for, to name it in a sentence ("Webshop
/// asks for your date of birth too"): the requested fields of its first
/// option (the first card in the app, else the first one to add), or, with
/// more than [OptionalWhat.maxFields] of them, the cards they come from.
OptionalWhat optionalWhat(DisclosurePickOne pickOne) {
  final owned =
      (pickOne.ownedOptions ?? const <DisclosureBundle>[]).firstOrNull;
  final toAdd =
      (pickOne.obtainableBundles ?? const <ObtainableBundle>[]).firstOrNull;
  (String, List<String>) ownedCard(SelectableCredentialInstance c) =>
      (c.name, [for (final a in c.attributes) a.effectiveDisplayName]);
  (String, List<String>) cardToAdd(CredentialDescriptor d) => (
    d.name,
    [
      for (final a in d.attributes)
        if (a.requestedValue != null) a.effectiveDisplayName,
    ],
  );
  final List<(String, List<String>)> cards = owned != null
      ? [for (final c in owned.credentials) ownedCard(c)]
      : toAdd != null
      ? [
          for (final d in toAdd.missing) cardToAdd(d),
          for (final c in toAdd.owned) ownedCard(c),
        ]
      : [
          for (final d in (pickOne.obtainableOptions ?? const []).take(1))
            cardToAdd(d),
        ];
  final fields = <String>{for (final (_, f) in cards) ...f}.toList();
  if (fields.isEmpty || fields.length > OptionalWhat.maxFields) {
    return OptionalWhat(byCard: true, names: [for (final (n, _) in cards) n]);
  }
  return OptionalWhat(byCard: false, names: fields);
}

/// The names [optionalWhat] found: the fields ("date of birth"), or the
/// cards they come from ([byCard]: "personal data").
class OptionalWhat {
  /// More fields than this are named by their cards.
  static const maxFields = 3;

  final bool byCard;
  final List<String> names;

  const OptionalWhat({required this.byCard, required this.names});

  @override
  bool operator ==(Object other) =>
      other is OptionalWhat &&
      other.byCard == byCard &&
      const ListEquality<String>().equals(other.names, names);

  @override
  int get hashCode => Object.hash(byCard, Object.hashAll(names));

  @override
  String toString() => "OptionalWhat(byCard: $byCard, names: $names)";
}

/// From this many fields a card in a sheet shows their names ("10 fields:
/// first names, surname, …") instead of its values: the sheet is for
/// choosing, the share screen shows every value.
const summaryFrom = 5;

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

/// The value of a card that was added for [pickOne] but does not match what
/// the request needs, compared with what it needs; null when there is none.
IssuanceMismatch? spotMismatch(
  DisclosurePickOne pickOne,
  IssueDuringDisclosure? plan,
) {
  final wrong = plan?.wrongCredentialIssued;
  if (wrong == null || !isEmptySpot(pickOne)) return null;
  final templates = [
    for (final d in pickOne.obtainableOptions ?? const <CredentialDescriptor>[])
      if (d.credentialId == wrong.credentialId) d,
  ];
  if (templates.isEmpty) return null;
  return issuanceMismatches(
    [wrong],
    [
      IssuanceStep(options: [IssuanceBundle(credentials: templates)]),
    ],
  ).firstOrNull;
}

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
        );
}

/// What the share button says.
enum ShareLabel { share, signAndShare, shareAndAdd, shareWithoutData, close }

/// The share button: its label, whether it can be pressed, and why not.
class ShareButtonState {
  final ShareLabel label;
  final bool enabled;

  /// The problem of a selected card that blocks sharing, and that card,
  /// for "Renew your address first."
  final CardProblem? blockedBy;
  final DisclosureBundle? blockedCard;

  /// Set when a required card has a problem it cannot get out of in Yivi:
  /// the button closes the session, with "Ask {issuer} for a new one."
  final String? cannotRenewFrom;

  /// The first empty spot, for "Add {name} first."
  final DisclosurePickOne? missing;

  /// An empty spot nothing can be added for from Yivi: the button closes
  /// the session, with "Get it from {issuer} first."
  final DisclosurePickOne? cannotAdd;

  const ShareButtonState({
    required this.label,
    required this.enabled,
    this.blockedBy,
    this.blockedCard,
    this.cannotRenewFrom,
    this.missing,
    this.cannotAdd,
  });
}

/// The share button for [state], with [selections] holding the user's pick
/// per pick-one index (missing entries use [defaultSelection]).
ShareButtonState shareButton(SessionState state, Map<int, int> selections) {
  final pickOnes = state.disclosurePlan?.disclosureChoicesOverview ?? const [];
  CardProblem? blockedBy;
  DisclosureBundle? blockedCard;
  String? cannotRenewFrom;
  DisclosurePickOne? missing;
  DisclosurePickOne? cannotAdd;
  var anyShared = false;

  for (final (i, pickOne) in pickOnes.indexed) {
    if (isEmptySpot(pickOne)) {
      if (addableOptions(pickOne).isEmpty) {
        cannotAdd ??= pickOne;
      } else {
        missing ??= pickOne;
      }
      continue;
    }
    final k = selectionOf(pickOne, selections[i]);
    if (k < 0) continue;
    anyShared = true;
    final bundle = pickOne.ownedOptions![k];
    final problem = problemOfBundle(bundle);
    if (problem == null || pickOne.optional) continue;
    blockedCard ??= bundle;
    blockedBy ??= problem;
    final stuck = fixFor(pickOne, bundle) == null && !canChange(pickOne);
    if (stuck) cannotRenewFrom ??= bundle.credentials.first.issuer.name;
  }

  if (cannotAdd != null) {
    return ShareButtonState(
      label: ShareLabel.close,
      enabled: true,
      cannotAdd: cannotAdd,
    );
  }
  if (cannotRenewFrom != null) {
    return ShareButtonState(
      label: ShareLabel.close,
      enabled: true,
      blockedBy: blockedBy,
      blockedCard: blockedCard,
      cannotRenewFrom: cannotRenewFrom,
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
    blockedBy: blockedBy,
    blockedCard: blockedCard,
    missing: missing,
  );
}

/// Whether the share screen says "{requestor} only gets what is above":
/// only when the button shares (nothing is missing or blocked) and at least
/// one card is in [selections]. Not while a card is still to be added, and
/// not when nothing is shared.
bool showFootnote(ShareButtonState button, Map<int, int> selections) =>
    button.enabled &&
    button.label != ShareLabel.close &&
    selections.values.any((k) => k >= 0);

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

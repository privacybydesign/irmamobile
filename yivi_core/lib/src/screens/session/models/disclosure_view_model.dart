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

/// Whether the share screen shows "Change" on [pickOne]: there is more
/// than one thing to choose from (cards in the app plus types that can be
/// added).
bool canChange(DisclosurePickOne pickOne) =>
    (pickOne.ownedOptions ?? const []).length + addableOptions(pickOne).length >
    1;

/// The type to add to replace [bundle] when it has a problem: an addable
/// option of the same credential type. Null when it cannot be renewed
/// from Yivi.
CredentialDescriptor? fixFor(
  DisclosurePickOne pickOne,
  DisclosureBundle bundle,
) {
  final ids = bundle.credentials.map((c) => c.credentialId).toSet();
  return addableOptions(
    pickOne,
  ).firstWhereOrNull((d) => ids.contains(d.credentialId));
}

/// What the share button says.
enum ShareLabel { share, signAndShare, shareAndAdd, shareWithoutData, close }

/// The share button: its label, whether it can be pressed, and why not.
class ShareButtonState {
  final ShareLabel label;
  final bool enabled;

  /// The problem of a selected card that blocks sharing, for "Replace the
  /// revoked card to share."
  final CardProblem? blockedBy;

  /// Set when a required card has a problem it cannot get out of in Yivi:
  /// the button closes the session, with "Ask {issuer} for a new one."
  final String? cannotRenewFrom;

  const ShareButtonState({
    required this.label,
    required this.enabled,
    this.blockedBy,
    this.cannotRenewFrom,
  });
}

/// The share button for [state], with [selections] holding the user's pick
/// per pick-one index (missing entries use [defaultSelection]).
ShareButtonState shareButton(SessionState state, Map<int, int> selections) {
  final pickOnes = state.disclosurePlan?.disclosureChoicesOverview ?? const [];
  CardProblem? blockedBy;
  String? cannotRenewFrom;
  var anyShared = false;

  for (final (i, pickOne) in pickOnes.indexed) {
    final k = selectionOf(pickOne, selections[i]);
    if (k < 0) continue;
    anyShared = true;
    final bundle = pickOne.ownedOptions![k];
    final problem = problemOfBundle(bundle);
    if (problem == null || pickOne.optional) continue;
    blockedBy ??= problem;
    final stuck = fixFor(pickOne, bundle) == null && !canChange(pickOne);
    if (stuck) cannotRenewFrom ??= bundle.credentials.first.issuer.name;
  }

  if (cannotRenewFrom != null) {
    return ShareButtonState(
      label: ShareLabel.close,
      enabled: true,
      blockedBy: blockedBy,
      cannotRenewFrom: cannotRenewFrom,
    );
  }
  final label = state.type == SessionType.signature
      ? ShareLabel.signAndShare
      : (state.offeredCredentials?.isNotEmpty ?? false)
      ? ShareLabel.shareAndAdd
      : anyShared
      ? ShareLabel.share
      : ShareLabel.shareWithoutData;
  return ShareButtonState(
    label: label,
    enabled: blockedBy == null,
    blockedBy: blockedBy,
  );
}

// --- Adding missing data (issue during disclosure) --------------------------

/// Whether [step] is satisfied: one of its options was added in full.
bool isStepDone(IssuanceStep step, Set<String> issuedCredentialIds) =>
    step.options.any(
      (b) => b.credentials.every(
        (c) => issuedCredentialIds.contains(c.credentialId),
      ),
    );

/// Whether every type in [bundle] can be added from Yivi.
bool canBeAddedBundle(IssuanceBundle bundle) =>
    bundle.credentials.every(canBeAdded);

/// The option of [step] that starts selected: the first that can be added.
int defaultStepOption(IssuanceStep step) =>
    step.options.indexWhere(canBeAddedBundle).clamp(0, step.options.length);

/// What the single button of the "Add data first" screen does for the
/// current step.
sealed class AddAction {
  const AddAction();
}

/// Open the issuer of [descriptor] ("Add mobile number" / "Opens …").
/// [again] after a card with the wrong value was added.
class AddCredential extends AddAction {
  final CredentialDescriptor descriptor;
  final bool again;

  const AddCredential(this.descriptor, {this.again = false});

  String get host => hostOf(descriptor.issueURL)!;
}

/// The selected option cannot be added, but another one can: the button
/// is disabled until the user picks that one.
class PickAddable extends AddAction {
  const PickAddable();
}

/// Nothing in this step can be added from Yivi: close the session, telling
/// the user to get it from [issuers] first.
class CloseCannotAdd extends AddAction {
  final List<String> issuers;

  const CloseCannotAdd(this.issuers);
}

/// The button for [step] with option [selected] chosen, given what was
/// added so far and the card with the wrong value, if any.
AddAction addActionFor(
  IssuanceStep step,
  int selected,
  Set<String> issuedCredentialIds, {
  Credential? wrongCredentialIssued,
}) {
  final bundle = step.options[selected.clamp(0, step.options.length - 1)];
  if (!canBeAddedBundle(bundle)) {
    if (step.options.any(canBeAddedBundle)) return const PickAddable();
    return CloseCannotAdd(
      bundle.credentials.map((c) => c.issuer.name).toSet().toList(),
    );
  }
  final next = bundle.credentials.firstWhere(
    (c) => !issuedCredentialIds.contains(c.credentialId),
    orElse: () => bundle.credentials.first,
  );
  final again =
      wrongCredentialIssued != null &&
      wrongCredentialIssued.credentialId == next.credentialId;
  return AddCredential(next, again: again);
}

// --- The issuance permission inside a request -------------------------------

/// A value on an offered card that does not satisfy the request waiting
/// underneath: shown in red, with a note before the user adds the card.
class IssuanceMismatch {
  final String credentialId;
  final String attributeName;
  final AttributeValue? offered;
  final AttributeValue required;

  const IssuanceMismatch({
    required this.credentialId,
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

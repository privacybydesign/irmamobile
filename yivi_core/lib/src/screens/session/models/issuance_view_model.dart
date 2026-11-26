import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:vcmrtd/vcmrtd.dart" show DocumentType;

import "../../../data/issuance_launcher.dart" show EmbeddedFlow, documentTypeOf;
import "../../../models/credential.dart";
import "../../../models/credential_store.dart";
import "../../../models/requestor_trust.dart";
import "../../../models/session_state.dart";
import "../../../widgets/credential_card/attribute_groups/attribute_group.dart"
    show claimPathKey;
import "disclosure_plan_view.dart"
    show allowedValues, missingDescriptors, sameValue;

// What the screens that ask whether to add a card show, worked out from the
// offer and the request waiting underneath only. Pure, so the rules can be
// unit tested without pumping a screen; the permission screen and the sheet
// both read them.

// --- The offer ----------------------------------------------------------------

/// The way on under an offer.
///
/// - [add]: "Add" ("Add {n} cards").
/// - [addAnyway]: nobody vouches for the issuer: a neutral "Add anyway",
///   with the reason above it.
/// - [retry]: in the sheet, a card that does not count for the request:
///   back to the step before, to try again.
/// - [dontReplace]: the same for a card that replaces the one in the app.
enum IssuancePrimary { add, addAnyway, retry, dontReplace }

/// Under the cards, when [IssuancePrimary.retry] or
/// [IssuancePrimary.dontReplace] is the way on: adding it all the same.
enum IssuanceLink { addAnyway, replaceAnyway }

/// The chip of an offered card inside a request.
///
/// - [notCounted]: a value is not what the request asks.
/// - [asked]: with several cards, the one the request asks for.
/// - [comesToo]: with several cards, one that comes along.
enum OfferTag { notCounted, asked, comesToo }

/// An offered card with what the screens show about it.
@immutable
final class OfferedCard {
  final Credential card;
  final OfferTag? tag;

  /// Claim paths ([claimPathKey]) whose value does not satisfy the request.
  final Set<String> mismatchedPaths;

  const OfferedCard(this.card, {this.tag, this.mismatchedPaths = const {}});
}

/// Everything the question whether to add an offer depends on.
@immutable
final class IssuanceOfferState {
  final List<Credential> cards;

  /// Who gives the cards (the first card's issuer); null without cards.
  final TrustedParty? issuer;

  /// Who asks for them, when the offer is part of a request.
  final TrustedParty? requestor;

  /// The values that do not satisfy the request; empty outside a request.
  final List<IssuanceMismatch> mismatches;

  /// Nobody vouches for the issuer, and no card misses the request.
  final bool risky;

  final IssuancePrimary primary;
  final IssuanceLink? link;

  /// A card replaces the one of its kind in the app.
  final bool singleton;

  /// The cards in order, each with its chip and mismatched values.
  final List<OfferedCard> perCard;

  const IssuanceOfferState({
    required this.cards,
    required this.issuer,
    required this.requestor,
    required this.mismatches,
    required this.risky,
    required this.primary,
    required this.link,
    required this.singleton,
    required this.perCard,
  });

  /// A card does not count for the request.
  bool get mismatched => mismatches.isNotEmpty;

  /// The mismatch the note above the cards names: the first.
  IssuanceMismatch? get note => mismatches.firstOrNull;
}

/// The question whether to add [cards]. Inside a request ([forRequest]) a
/// card whose value the request cannot use does not count; with
/// [retryOnMismatch] (the sheet, which has a step to go back to) trying
/// again then comes first and adding it anyway second. The full-screen
/// permission keeps "Add".
IssuanceOfferState issuanceOfferOf(
  List<Credential> cards, {
  SessionState? forRequest,
  required bool retryOnMismatch,
}) {
  final missing = forRequest == null
      ? const <CredentialDescriptor>[]
      : missingDescriptors(forRequest.disclosurePlan);
  final mismatches = issuanceMismatches(cards, missing);
  final mismatched = mismatches.isNotEmpty;
  final issuer = cards.firstOrNull?.issuer;
  final risky =
      !mismatched &&
      issuer != null &&
      requestorTrustOf(issuer) == RequestorTrust.unknown;
  final singleton = cards.any((c) => c.isSingleton);
  final retry = mismatched && retryOnMismatch;
  final used = {for (final d in missing) d.credentialId};
  OfferTag? tagOf(Credential card) {
    if (forRequest == null) return null;
    if (issuanceMismatches([card], missing).isNotEmpty) {
      return OfferTag.notCounted;
    }
    if (cards.length == 1) return null;
    return used.contains(card.credentialId)
        ? OfferTag.asked
        : OfferTag.comesToo;
  }

  return IssuanceOfferState(
    cards: cards,
    issuer: issuer,
    requestor: forRequest?.requestor,
    mismatches: mismatches,
    risky: risky,
    primary: retry
        ? (singleton ? IssuancePrimary.dontReplace : IssuancePrimary.retry)
        : risky
        ? IssuancePrimary.addAnyway
        : IssuancePrimary.add,
    link: retry
        ? (singleton ? IssuanceLink.replaceAnyway : IssuanceLink.addAnyway)
        : null,
    singleton: singleton,
    perCard: [
      for (final card in cards)
        OfferedCard(
          card,
          tag: tagOf(card),
          mismatchedPaths: {
            for (final m in mismatches)
              if (m.credentialId == card.credentialId)
                claimPathKey(m.claimPath),
          },
        ),
    ],
  );
}

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

/// The values of [offered] that are none of the values the request waiting
/// underneath allows, per [missing] descriptor of the card's type.
List<IssuanceMismatch> issuanceMismatches(
  List<Credential> offered,
  List<CredentialDescriptor> missing,
) {
  final out = <IssuanceMismatch>[];
  for (final card in offered) {
    final templates = [
      for (final d in missing)
        if (d.credentialId == card.credentialId) d,
    ];
    for (final template in templates) {
      for (final wanted in template.attributes) {
        final allowed = allowedValues(wanted);
        if (allowed.isEmpty) continue;
        final got = card.attributes.firstWhereOrNull(
          (a) => const ListEquality<dynamic>().equals(
            a.claimPath,
            wanted.claimPath,
          ),
        );
        if (allowed.any((v) => sameValue(got?.value, v))) continue;
        out.add(
          IssuanceMismatch(
            credentialId: card.credentialId,
            claimPath: wanted.claimPath,
            attributeName: wanted.effectiveDisplayName,
            offered: got?.value,
            required: allowed.first,
          ),
        );
      }
    }
  }
  return out;
}

// --- Adding a card in the sheet -------------------------------------------

/// How adding a card goes: Yivi's own steps ([flow]: an e-mail address, a
/// phone number, a document), or the issuer's website ([flow] null).
@immutable
final class IssuePlan {
  final EmbeddedFlow? flow;

  /// The document the card is read from, for [EmbeddedFlow.document].
  final DocumentType? document;

  const IssuePlan({required this.flow, required this.document});

  /// The intro of "How it goes" on the card's details, if Yivi's own steps
  /// add it (`data.add.details.how_*`).
  String? get howIntroKey => switch (flow) {
    EmbeddedFlow.email => "data.add.details.how_email",
    EmbeddedFlow.phone => "data.add.details.how_phone",
    EmbeddedFlow.document when document != null =>
      "data.add.details.how_document",
    _ => null,
  };

  /// How many steps adding takes, for the progress: the details, the steps
  /// that prove it, and adding it. A website is one step (3 in all); an
  /// e-mail address or phone number two, the address and the code (4); a
  /// document three, how to hold it, scanning or typing it in, and the chip
  /// (5), or [documentTotal] once its flow has started (a fourth step once
  /// the issuer asks for a face check).
  int total({int? documentTotal}) => switch (flow) {
    EmbeddedFlow.email || EmbeddedFlow.phone => 4,
    EmbeddedFlow.document when document != null => documentTotal ?? 5,
    _ => 3,
  };
}

/// Adding [d], which Yivi adds with [flow] (null: the issuer's website).
IssuePlan issuePlanOf(CredentialDescriptor d, EmbeddedFlow? flow) => IssuePlan(
  flow: flow,
  document: flow == EmbeddedFlow.document
      ? documentTypeOf(d.credentialId)
      : null,
);

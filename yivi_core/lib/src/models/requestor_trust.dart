import "schemaless/schemaless_events.dart";

/// How far a requestor is vouched for, as the session screens show it.
///
/// - [yivi]: Yivi vouches (the high rung, or `verified` before the trust
///   ladder): green.
/// - [elsewhere]: another trusted party vouches, for example a trust service
///   on the EU trusted list (the medium rung): blue, just as calm.
/// - [unknown]: nobody vouches (the low rung, or not `verified`): red, and
///   sharing asks once more.
/// - [unevaluated]: the ladder was not evaluated: no colour, no claim.
///
/// Medium and high both clear the bar, for every session type; the colour
/// says who vouches (docs/share-recipient-plan.md, Q2).
enum RequestorTrust { yivi, elsewhere, unknown, unevaluated }

/// The one mapping from what irmago sends to the tier. An irmago with the
/// trust ladder sends [TrustedParty.trustLevel]; an older one
/// [TrustedParty.verified], with [TrustedParty.trustSource] saying whether
/// it is Yivi that vouches.
RequestorTrust requestorTrustOf(TrustedParty party) {
  final level = party.trustLevel;
  if (level == null) {
    if (!party.verified) return RequestorTrust.unknown;
    // Verified, but by whom: a certificate from another CA is vouched for
    // just as well, by someone other than Yivi.
    return switch (party.trustSource) {
      "other" || "eu_trusted_list" => RequestorTrust.elsewhere,
      _ => RequestorTrust.yivi,
    };
  }
  return switch (level) {
    "high" => RequestorTrust.yivi,
    "medium" => RequestorTrust.elsewhere,
    "low" => RequestorTrust.unknown,
    // An empty rung is irmago's "not evaluated" in old log rows.
    "" => RequestorTrust.unevaluated,
    // A rung this app does not know: the cautious reading, never a claim
    // of trust it cannot back.
    _ => RequestorTrust.unknown,
  };
}

extension RequestorTrustX on RequestorTrust {
  /// Medium and high: the page stays calm and Share is the normal button.
  bool get vouched =>
      this == RequestorTrust.yivi || this == RequestorTrust.elsewhere;

  /// Nobody vouches: the red page, the banner and "Share anyway".
  bool get risky => this == RequestorTrust.unknown;
}

/// Where the trust in an [RequestorTrust.elsewhere] party comes from, for
/// its label (docs/share-recipient-plan.md, Q3): "Verified in the EU" only
/// when it really is an EU trusted list, "Verified by {anchor}" for another
/// named anchor, and "Identity confirmed" when irmago does not say.
enum ElsewhereSource { euTrustedList, namedAnchor, unspecified }

ElsewhereSource elsewhereSourceOf(TrustedParty party) {
  if (party.trustSource == "eu_trusted_list") {
    return ElsewhereSource.euTrustedList;
  }
  final anchor = party.trustAnchor;
  if (anchor != null && anchor.isNotEmpty) return ElsewhereSource.namedAnchor;
  return ElsewhereSource.unspecified;
}

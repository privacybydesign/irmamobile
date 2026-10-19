import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/log_entry.dart" show CredentialFormat;
import "package:yivi_core/src/models/requestor_trust.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/screens/session/models/technical_details.dart";

TrustedParty _party({
  bool verified = false,
  String? level,
  String? source,
  String? anchor,
  TrustEvidence? evidence,
  String id = "pbdf-requestors.webshopnoord",
}) => TrustedParty(
  id: id,
  name: "Webshop Noord",
  url: null,
  parent: null,
  verified: verified,
  trustLevel: level,
  trustSource: source,
  trustAnchor: anchor,
  evidence: evidence,
);

/// Keys as they are, with parameters appended: enough to see which string
/// a row uses and what went into it.
String _t(String key, [Map<String, String>? params]) =>
    params == null ? key : "$key ${params.values.join(" / ")}";

SessionState _session(TrustedParty party, {String protocol = "irma"}) =>
    SessionState(
      id: 1,
      protocol: protocol,
      type: SessionType.disclosure,
      status: SessionStatus.requestPermission,
      requestor: party,
      responseMode: protocol == "openid4vp" ? "direct_post.jwt" : null,
    );

SelectableCredentialInstance _card(String name, CredentialFormat format) =>
    SelectableCredentialInstance(
      credentialId: name,
      hash: "hash-$name",
      name: name,
      issuer: _party(verified: true, id: "issuer"),
      format: format,
      attributes: [
        Attribute(
          claimPath: ["value"],
          displayName: "Value",
          value: AttributeValue(
            type: AttributeType.string,
            string: "sanne@devries.example",
          ),
        ),
      ],
      revoked: false,
      revocationSupported: false,
    );

void main() {
  group("requestorTrustOf", () {
    test("before the trust ladder: verified or not", () {
      expect(requestorTrustOf(_party(verified: true)), RequestorTrust.yivi);
      expect(requestorTrustOf(_party()), RequestorTrust.unknown);
    });

    test("verified by a CA other than Yivi's: someone else vouches", () {
      expect(
        requestorTrustOf(_party(verified: true, source: "yivi_trust_list")),
        RequestorTrust.yivi,
      );
      expect(
        requestorTrustOf(_party(verified: true, source: "yivi_scheme")),
        RequestorTrust.yivi,
      );
      expect(
        requestorTrustOf(_party(verified: true, source: "other")),
        RequestorTrust.elsewhere,
      );
    });

    test("the ladder's rungs, which win over verified", () {
      expect(requestorTrustOf(_party(level: "high")), RequestorTrust.yivi);
      expect(
        requestorTrustOf(_party(level: "medium")),
        RequestorTrust.elsewhere,
      );
      expect(
        requestorTrustOf(_party(verified: true, level: "low")),
        RequestorTrust.unknown,
      );
      expect(requestorTrustOf(_party(level: "")), RequestorTrust.unevaluated);
    });

    test("a rung this app doesn't know is read cautiously", () {
      expect(requestorTrustOf(_party(level: "ultra")), RequestorTrust.unknown);
    });

    test("medium and high are vouched for; only unknown is risky", () {
      expect(RequestorTrust.yivi.vouched, isTrue);
      expect(RequestorTrust.elsewhere.vouched, isTrue);
      expect(RequestorTrust.elsewhere.risky, isFalse);
      expect(RequestorTrust.unknown.risky, isTrue);
      expect(RequestorTrust.unevaluated.vouched, isFalse);
      expect(RequestorTrust.unevaluated.risky, isFalse);
    });

    test("an EU trusted list, a named anchor, or nothing said", () {
      expect(
        elsewhereSourceOf(_party(source: "eu_trusted_list", anchor: "QTSP")),
        ElsewhereSource.euTrustedList,
      );
      expect(
        elsewhereSourceOf(_party(source: "other", anchor: "Some CA")),
        ElsewhereSource.namedAnchor,
      );
      expect(elsewhereSourceOf(_party()), ElsewhereSource.unspecified);
    });
  });

  group("technicalDetailsOf", () {
    test("IRMA, before the ladder: what the app knows", () {
      final groups = technicalDetailsOf(_session(_party(verified: true)), [
        _card("Email address", CredentialFormat.idemix),
      ], _t);
      expect(groups.map((g) => g.title), [
        "share.tech.group.who",
        "share.tech.group.how",
        "share.tech.group.what",
      ]);
      final who = {for (final r in groups[0].rows) r.label: r};
      expect(who["share.tech.row.name"]!.value, "Webshop Noord");
      expect(
        who["share.tech.row.identifier"]!.value,
        "pbdf-requestors.webshopnoord",
      );
      expect(who["share.tech.row.identifier"]!.mono, isTrue);
      expect(
        who["share.tech.row.trust_level"]!.value,
        "share.tech.level.verified",
      );
      // Nothing irmago didn't send.
      expect(who.containsKey("share.tech.row.trust_source"), isFalse);
      expect(who.containsKey("share.tech.row.cert_issuer"), isFalse);

      final how = {for (final r in groups[1].rows) r.label: r.value};
      expect(how["share.tech.row.protocol"], "share.tech.protocol.irma");
      expect(how["share.tech.row.session"], "share.tech.session.disclosure");
      expect(how.containsKey("share.tech.row.response"), isFalse);

      expect(groups[2].rows.single.label, "Email address");
      expect(
        groups[2].rows.single.value,
        "share.tech.card share.tech.format.idemix / Webshop Noord",
      );
    });

    test("OpenID4VP at medium: the trust system, anchor and certificate", () {
      final groups = technicalDetailsOf(
        _session(
          _party(
            id: "x509_san_dns:webshopnoord.nl",
            level: "medium",
            source: "eu_trusted_list",
            anchor: "Example Trust Services",
            evidence: TrustEvidence(
              certificate: TrustCertificate(
                subject: "CN=webshopnoord.nl",
                issuer: "Example Trust Services CA",
                notAfter: 1893456000, // 2030-01-01
              ),
            ),
          ),
          protocol: "openid4vp",
        ),
        [_card("Email address", CredentialFormat.sdjwtvc)],
        _t,
      );
      final who = {for (final r in groups[0].rows) r.label: r.value};
      expect(who["share.tech.row.trust_level"], "share.tech.level.medium");
      expect(
        who["share.tech.row.trust_source"],
        "share.tech.source.eu_trusted_list",
      );
      expect(who["share.tech.row.trust_anchor"], "Example Trust Services");
      expect(who["share.tech.row.cert_subject"], "CN=webshopnoord.nl");
      expect(who["share.tech.row.cert_valid"], "2030-01-01");
      final how = {for (final r in groups[1].rows) r.label: r.value};
      expect(how["share.tech.row.response"], "direct_post.jwt");
    });

    test("the copied text holds no personal values", () {
      final text = technicalDetailsText(
        technicalDetailsOf(_session(_party(verified: true)), [
          _card("Email address", CredentialFormat.idemix),
        ], _t),
      );
      expect(
        text,
        contains("share.tech.row.protocol: share.tech.protocol.irma"),
      );
      expect(text, isNot(contains("sanne@devries.example")));
    });
  });
}

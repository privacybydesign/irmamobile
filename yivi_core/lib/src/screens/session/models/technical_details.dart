import "../../../models/log_entry.dart" show CredentialFormat;
import "../../../models/schemaless/session_state.dart";

/// One line of the technical details: a label and its value. Identifiers
/// are [mono]spaced.
class TechRow {
  final String label;
  final String value;
  final bool mono;

  const TechRow(this.label, this.value, {this.mono = false});
}

class TechGroup {
  final String title;
  final List<TechRow> rows;

  const TechGroup(this.title, this.rows);
}

typedef Translate = String Function(String key, [Map<String, String>? params]);

/// The technical details of a request, for the curious: who asks (its
/// identifier and where the trust in it comes from), how the data travels
/// (protocol, session, response) and what they get (each card's format and
/// issuer). A value irmago does not send leaves its row out; no row is ever
/// empty. Never contains personal values: only identifiers and formats.
List<TechGroup> technicalDetailsOf(
  SessionState session,
  List<SelectableCredentialInstance> shared,
  Translate t,
) {
  final party = session.requestor;
  final evidence = party.evidence;
  final certificate = evidence?.certificate;

  final level = switch (party.trustLevel) {
    "high" => t("share.tech.level.high"),
    "medium" => t("share.tech.level.medium"),
    "low" => t("share.tech.level.low"),
    null =>
      party.verified
          ? t("share.tech.level.verified")
          : t("share.tech.level.not_verified"),
    _ => t("share.tech.level.unevaluated"),
  };
  final source = switch (party.trustSource) {
    "yivi_scheme" => t("share.tech.source.yivi_scheme"),
    "yivi_trust_list" => t("share.tech.source.yivi_trust_list"),
    "eu_trusted_list" => t("share.tech.source.eu_trusted_list"),
    "other" => party.trustAnchor,
    _ => null,
  };
  final notAfter = certificate?.notAfter;

  final who = [
    TechRow(t("share.tech.row.name"), party.name),
    if (party.id.isNotEmpty)
      TechRow(t("share.tech.row.identifier"), party.id, mono: true),
    TechRow(t("share.tech.row.trust_level"), level),
    if (source != null && source.isNotEmpty)
      TechRow(t("share.tech.row.trust_source"), source),
    if (party.trustAnchor case final anchor?
        when anchor.isNotEmpty && party.trustSource != "other")
      TechRow(t("share.tech.row.trust_anchor"), anchor),
    if (evidence?.registrationId case final id? when id.isNotEmpty)
      TechRow(t("share.tech.row.registration"), id, mono: true),
    if (certificate != null) ...[
      TechRow(
        t("share.tech.row.cert_subject"),
        certificate.subject,
        mono: true,
      ),
      TechRow(t("share.tech.row.cert_issuer"), certificate.issuer),
      if (notAfter != null)
        TechRow(t("share.tech.row.cert_valid"), _date(notAfter)),
    ],
  ];

  final how = [
    TechRow(t("share.tech.row.protocol"), switch (session.protocol) {
      "irma" => t("share.tech.protocol.irma"),
      "openid4vp" => t("share.tech.protocol.openid4vp"),
      "openid4vci" => t("share.tech.protocol.openid4vci"),
      final other => other,
    }),
    TechRow(
      t("share.tech.row.session"),
      t("share.tech.session.${session.type.name}"),
    ),
    if (session.responseMode case final mode? when mode.isNotEmpty)
      TechRow(t("share.tech.row.response"), mode, mono: true),
  ];

  final what = [
    for (final c in shared)
      TechRow(
        c.name,
        t("share.tech.card", {
          "format": _format(c.format, t),
          "issuer": c.issuer.name,
        }),
      ),
  ];

  return [
    TechGroup(t("share.tech.group.who"), who),
    TechGroup(t("share.tech.group.how"), how),
    if (what.isNotEmpty) TechGroup(t("share.tech.group.what"), what),
  ];
}

/// All details as plain text, for "Copy all details".
String technicalDetailsText(List<TechGroup> groups) => [
  for (final g in groups) ...[
    g.title,
    for (final r in g.rows) "${r.label}: ${r.value}",
    "",
  ],
].join("\n").trimRight();

String _format(CredentialFormat? format, Translate t) => switch (format) {
  CredentialFormat.idemix => t("share.tech.format.idemix"),
  CredentialFormat.sdjwtvc => t("share.tech.format.sdjwtvc"),
  CredentialFormat.msoMdoc => t("share.tech.format.mdoc"),
  null => t("share.tech.format.unknown"),
};

/// ISO date (yyyy-mm-dd, UTC) of [seconds] since the epoch: technical
/// details are read by people who expect it.
String _date(int seconds) {
  final d = DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  String two(int n) => n.toString().padLeft(2, "0");
  return "${d.year}-${two(d.month)}-${two(d.day)}";
}

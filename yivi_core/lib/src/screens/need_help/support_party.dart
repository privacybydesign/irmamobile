import "../../data/recent_session_parties.dart";
import "../../models/credential.dart";
import "../../models/support_directory.dart";

/// An organisation behind an issuer or verifier, and where its own support
/// lives. Questions about what an organisation does with your data go there,
/// not to Yivi support.
class SupportParty {
  final TrustedParty party;

  /// The organisation's website: the support page from the scheme when it
  /// has one, otherwise its site derived from the requestor's hostname.
  final Uri? website;

  /// The [website] is not from the scheme or the organisation itself, but
  /// derived from a hostname. It can be a supplier's site, or the wrong
  /// part of a large organisation, so it is never the only way forward.
  final bool websiteGuessed;

  /// Where to mail the organisation: the support address of its requestor
  /// when the scheme has one, otherwise the contact address of its issuer.
  final String? email;

  /// Yivi (or the Privacy by Design Foundation behind it) issued this data or
  /// made this request itself, so Yivi support is the organisation's support.
  final bool isYivi;

  const SupportParty({
    required this.party,
    this.website,
    this.websiteGuessed = false,
    this.email,
    this.isYivi = false,
  });

  String get name => party.name;

  /// Issuer and requestor ids of Yivi's own parties.
  static const _yiviIds = {
    "pbdf.pbdf",
    "pbdf.sidn-pbdf",
    "pbdf-requestors.pbdf",
    "pbdf-requestors.sidn-pbdf",
  };

  static const yiviEmail = "support@yivi.app";

  /// Yivi's own domains: a server on one of these is Yivi's, scheme or not.
  static const _yiviDomains = {"yivi.app", "irma.app", "yiviconnect.nl"};

  /// Tells parties apart. A server that is not in the scheme has no id, only
  /// its hostname as name.
  static String keyOf(TrustedParty party) =>
      RecentSessionParties.partyKey(party);

  /// Looks up where [party] offers support. Returns null when the party is
  /// unknown, so callers fall back to asking the user. Without a
  /// [directory] (not loaded yet) only what the party itself says counts.
  static SupportParty? resolve(
    TrustedParty? party,
    SupportDirectory? directory,
  ) {
    if (party == null || party.name.trim().isEmpty) return null;
    // What the organisation states for its end users comes first: the
    // support address and support page of its requestor. An issuer's
    // contact details are not always meant for end users, and a hostname
    // only gives a guess.
    final requestor = _requestorOf(party, directory);
    final issuer =
        directory?.issuer(party.id) ?? _pairedIssuer(party, directory);
    final email =
        _usableEmail(requestor?.supportEmail) ??
        _usableEmail(issuer?.contactEmail);
    final stated =
        _httpUri(requestor?.supportUrl) ??
        _httpUri(party.url) ??
        _httpUri(issuer?.contactAddress);
    final website =
        stated ??
        _siteOfRequestor(party, directory) ??
        _siteOfUnknownServer(party);
    return SupportParty(
      party: party,
      website: website,
      websiteGuessed: stated == null && website != null,
      email: email,
      isYivi:
          _yiviIds.contains(party.id) ||
          email == yiviEmail ||
          _isYiviDomain(website?.host),
    );
  }

  /// Every organisation in the schemes the user can be put through to, by
  /// name: verified requestors first, because those are who users meet in
  /// sessions, then issuers not already covered by a requestor. Demo
  /// schemes are left out. Yivi's own parties are in; they lead to Yivi
  /// support.
  static List<SupportParty> directoryOf(
    SupportDirectory directory,
    String lang,
  ) {
    final byName = <String, SupportParty>{};
    final coveredIssuers = <String>{};

    void add(TrustedParty party) {
      final org = resolve(party, directory);
      if (org == null) return;
      byName.putIfAbsent(org.name.trim().toLowerCase(), () => org);
    }

    for (final requestor in directory.requestors) {
      if (requestor.demo) continue;
      final party = TrustedParty(
        id: requestor.id,
        name: translatedIn(requestor.name, lang),
        url: null,
        parent: null,
        verified: requestor.verified,
        imagePath: requestor.logoPath,
      );
      final paired = _pairedIssuer(party, directory);
      if (paired != null) coveredIssuers.add(paired.id);
      add(party);
    }
    for (final issuer in directory.issuers) {
      if (issuer.demo || coveredIssuers.contains(issuer.id)) continue;
      add(
        TrustedParty(
          id: issuer.id,
          name: translatedIn(issuer.name, lang),
          url: null,
          parent: null,
          verified: true,
        ),
      );
    }

    return byName.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  static const _requestorsSuffix = "-requestors";

  /// Requestors in a requestor scheme mostly mirror an issuer in the
  /// matching issuer scheme: `pbdf-requestors.cis` and `pbdf.cis`. That
  /// issuer has contact details for when the requestor has none.
  static SupportIssuer? _pairedIssuer(
    TrustedParty party,
    SupportDirectory? directory,
  ) {
    final dot = party.id.indexOf(".");
    if (directory == null || dot < 0) return null;
    final scheme = party.id.substring(0, dot);
    if (!scheme.endsWith(_requestorsSuffix)) return null;
    final issuerScheme = scheme.substring(
      0,
      scheme.length - _requestorsSuffix.length,
    );
    return directory.issuer("$issuerScheme${party.id.substring(dot)}");
  }

  /// The requestor behind [party]: the requestor itself, or for an issuer
  /// the requestor it is paired with (`pbdf.cis` and `pbdf-requestors.cis`),
  /// so an organisation has the same support address whether the user got
  /// there from a request or from data it issued.
  static SupportRequestor? _requestorOf(
    TrustedParty party,
    SupportDirectory? directory,
  ) {
    final dot = party.id.indexOf(".");
    if (directory == null || dot < 0) return null;
    final scheme = party.id.substring(0, dot);
    return directory.requestor(party.id) ??
        (scheme.endsWith(_requestorsSuffix)
            ? null
            : directory.requestor(
                "$scheme$_requestorsSuffix${party.id.substring(dot)}",
              ));
  }

  static Uri? _siteOfRequestor(
    TrustedParty party,
    SupportDirectory? directory,
  ) {
    final hostnames = directory?.requestor(party.id)?.hostnames;
    if (hostnames == null || hostnames.isEmpty) return null;
    return siteOfHostname(hostnames.first);
  }

  /// A domain name, not an IP address: its last label starts with a letter.
  static final _hostname = RegExp(
    r"^[a-z0-9-]+(\.[a-z0-9-]+)*\.[a-z][a-z0-9-]*$",
  );

  /// Second levels many countries register domains under, as in `co.uk`,
  /// `com.au` and `or.jp`. Not the whole public suffix list, but the
  /// pattern behind most of it.
  static const _countrySecondLevels = {
    "ac", "co", "com", "edu", "go", "gob", "gov", //
    "ltd", "ne", "net", "or", "org", "plc", "sch",
  };

  /// A server that is not in the scheme is named after its hostname, e.g.
  /// `is.demo.staging.yivi.app`. Verified names like "Ver.iD" are left alone.
  static Uri? _siteOfUnknownServer(TrustedParty party) =>
      party.verified ? null : siteOfHostname(party.name);

  static bool _isYiviDomain(String? host) =>
      host != null &&
      _yiviDomains.any((d) => host == d || host.endsWith(".$d"));

  /// `inzage.stichtingcis.nl` → `https://stichtingcis.nl`. Requestor
  /// hostnames are often a subdomain for the Yivi integration; the site one
  /// level up is where people find the organisation's contact details.
  /// `portal.example.co.uk` → `https://example.co.uk`. Null for anything
  /// that is not a domain name, such as an IP address or `localhost`.
  static Uri? siteOfHostname(String hostname) {
    final host = hostname.trim().toLowerCase();
    if (!_hostname.hasMatch(host)) return null;
    final labels = host.split(".");
    final underCountry =
        labels.length > 2 &&
        labels.last.length == 2 &&
        _countrySecondLevels.contains(labels[labels.length - 2]);
    final depth = underCountry ? 3 : 2;
    return Uri.https(labels.sublist(labels.length - depth).join("."));
  }

  static Uri? _httpUri(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme != "https" && uri.scheme != "http") return null;
    return uri;
  }

  static String? _usableEmail(String? raw) {
    final email = raw?.trim().toLowerCase();
    if (email == null || !email.contains("@")) return null;
    final local = email.split("@").first;
    if (local.startsWith("noreply") || local.startsWith("no-reply")) {
      return null;
    }
    return email;
  }
}

import "../../data/irma_repository.dart";
import "../../models/irma_configuration.dart";
import "../../models/schemaless/schemaless_events.dart";

/// An organisation behind an issuer or verifier, and where its own support
/// lives. Questions about what an organisation does with your data go there,
/// not to Yivi support.
class SupportParty {
  final TrustedParty party;

  /// The organisation's website: the support page from the scheme when it
  /// has one, otherwise its site derived from the requestor's hostname.
  final Uri? website;

  final String? email;

  /// Yivi (or the Privacy by Design Foundation behind it) issued this data or
  /// made this request itself, so Yivi support is the organisation's support.
  final bool isYivi;

  const SupportParty({
    required this.party,
    this.website,
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

  static const _yiviEmail = "support@yivi.app";

  /// Yivi's own domains: a server on one of these is Yivi's, scheme or not.
  static const _yiviDomains = {"yivi.app", "irma.app"};

  /// Tells parties apart. A server that is not in the scheme has no id, only
  /// its hostname as name.
  static String keyOf(TrustedParty party) =>
      party.id.isNotEmpty ? party.id : party.name;

  /// Looks up where [party] offers support. Returns null when the party is
  /// unknown, so callers fall back to asking the user.
  static SupportParty? resolve(TrustedParty? party, IrmaConfiguration? config) {
    if (party == null || party.name.trim().isEmpty) return null;

    final issuer = config?.issuers[party.id] ?? _pairedIssuer(party, config);
    final email = _usableEmail(issuer?.contactEmail);
    final website =
        _httpUri(party.url) ??
        _httpUri(issuer?.contactAddress) ??
        _siteOfRequestor(party, config) ??
        _siteOfUnknownServer(party);

    return SupportParty(
      party: party,
      website: website,
      email: email,
      isYivi:
          _yiviIds.contains(party.id) ||
          email == _yiviEmail ||
          _isYiviDomain(website?.host),
    );
  }

  /// [resolve], with the scheme configuration from [repo] once it loaded.
  static SupportParty? resolveIn(IrmaRepository repo, TrustedParty? party) =>
      resolve(party, configOf(repo));

  static IrmaConfiguration? configOf(IrmaRepository repo) {
    try {
      return repo.irmaConfiguration;
    } catch (_) {
      // Not loaded yet.
      return null;
    }
  }

  /// Every organisation in the scheme the user can be put through to, by
  /// name: verified requestors first, because those are who users meet in
  /// sessions, then issuers not already covered by a requestor. Demo
  /// schemes are left out. Yivi's own parties are in; they lead to Yivi
  /// support.
  static List<SupportParty> directory(IrmaConfiguration config, String lang) {
    final demo = {
      for (final s in config.schemeManagers.values)
        if (s.demo) s.id,
      for (final s in config.requestorSchemes.values)
        if (s.demo) s.id,
    };
    bool inDemo(String id) => demo.contains(id.split(".").first);

    final byName = <String, SupportParty>{};
    final coveredIssuers = <String>{};
    void add(TrustedParty party) {
      final org = resolve(party, config);
      if (org == null) return;
      byName.putIfAbsent(org.name.trim().toLowerCase(), () => org);
    }

    for (final requestor in config.requestors.values) {
      final id = requestor.id;
      if (id == null || inDemo(id)) continue;
      final party = TrustedParty(
        id: id,
        name: requestor.name.translate(lang, fallback: ""),
        url: null,
        parent: null,
        verified: !requestor.unverified,
        imagePath: requestor.logoPath,
      );
      final paired = _pairedIssuer(party, config);
      if (paired != null) coveredIssuers.add(paired.fullId);
      add(party);
    }
    for (final issuer in config.issuers.values) {
      if (inDemo(issuer.fullId) || coveredIssuers.contains(issuer.fullId)) {
        continue;
      }
      add(
        TrustedParty(
          id: issuer.fullId,
          name: issuer.name.translate(lang, fallback: ""),
          url: null,
          parent: null,
          verified: true,
        ),
      );
    }

    return byName.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// Requestors in a requestor scheme mostly mirror an issuer in the
  /// matching issuer scheme: `pbdf-requestors.cis` and `pbdf.cis`. That
  /// issuer has contact details the requestor scheme does not.
  static Issuer? _pairedIssuer(TrustedParty party, IrmaConfiguration? config) {
    final dot = party.id.indexOf(".");
    if (config == null || dot < 0) return null;
    final scheme = party.id.substring(0, dot);
    if (!scheme.endsWith("-requestors")) return null;
    final issuerScheme = scheme.substring(0, scheme.length - 11);
    return config.issuers["$issuerScheme${party.id.substring(dot)}"];
  }

  static Uri? _siteOfRequestor(TrustedParty party, IrmaConfiguration? config) {
    final hostnames = config?.requestors.values
        .where((r) => r.id == party.id)
        .expand((r) => r.hostnames);
    if (hostnames == null || hostnames.isEmpty) return null;
    return siteOfHostname(hostnames.first);
  }

  static final _hostname = RegExp(r"^[a-z0-9-]+(\.[a-z0-9-]+)+$");

  /// A server that is not in the scheme is named after its hostname, e.g.
  /// `is.demo.staging.yivi.app`. Verified names like "Ver.iD" are left alone.
  static Uri? _siteOfUnknownServer(TrustedParty party) {
    final name = party.name.trim().toLowerCase();
    if (party.verified || !_hostname.hasMatch(name)) return null;
    return siteOfHostname(name);
  }

  static bool _isYiviDomain(String? host) =>
      host != null &&
      _yiviDomains.any((d) => host == d || host.endsWith(".$d"));

  /// `inzage.stichtingcis.nl` → `https://stichtingcis.nl`. Requestor
  /// hostnames are often a subdomain for the Yivi integration; the site one
  /// level up is where people find the organisation's contact details.
  static Uri? siteOfHostname(String hostname) {
    final labels = hostname
        .trim()
        .toLowerCase()
        .split(".")
        .where((label) => label.isNotEmpty)
        .toList();
    if (labels.length < 2) return null;
    final domain = labels.sublist(labels.length - 2).join(".");
    return Uri.https(domain);
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

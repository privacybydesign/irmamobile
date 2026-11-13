import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/irma_configuration.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/models/translated_value.dart";
import "package:yivi_core/src/screens/need_help/support_party.dart";

TrustedParty _party(String id, {String name = "Org", String? url}) =>
    TrustedParty(id: id, name: name, url: url, parent: null, verified: true);

Issuer _issuer(
  String scheme,
  String id, {
  String address = "",
  String email = "",
}) => Issuer(
  id: id,
  name: const TranslatedValue.empty(),
  schemeManagerId: scheme,
  contactAddress: address,
  contactEmail: email,
);

IrmaConfiguration _config({
  List<Issuer> issuers = const [],
  Map<String, RequestorInfo> requestors = const {},
  Map<String, RequestorScheme> requestorSchemes = const {},
}) => IrmaConfiguration(
  schemeManagers: const {},
  requestorSchemes: requestorSchemes,
  requestors: requestors,
  issuers: {for (final i in issuers) i.fullId: i},
  credentialTypes: const {},
  attributeTypes: const {},
  issueWizards: const {},
  path: "",
);

void main() {
  test("unknown or nameless parties resolve to null", () {
    expect(SupportParty.resolve(null, _config()), isNull);
    expect(SupportParty.resolve(_party("x.y", name: " "), _config()), isNull);
  });

  test("issuer: website and email from the scheme", () {
    final org = SupportParty.resolve(
      _party("pbdf.cis"),
      _config(
        issuers: [
          _issuer(
            "pbdf",
            "cis",
            address: "https://stichtingcis.nl/",
            email: "info@stichtingcis.nl",
          ),
        ],
      ),
    )!;
    expect(org.website, Uri.parse("https://stichtingcis.nl/"));
    expect(org.email, "info@stichtingcis.nl");
    expect(org.isYivi, isFalse);
  });

  test("the party's own url wins over the scheme", () {
    final org = SupportParty.resolve(
      _party("pbdf.cis", url: "https://help.example.org"),
      _config(issuers: [_issuer("pbdf", "cis", address: "https://cis.nl")]),
    )!;
    expect(org.website, Uri.parse("https://help.example.org"));
  });

  test("requestor: contact details from the paired issuer", () {
    final org = SupportParty.resolve(
      _party("pbdf-requestors.cis"),
      _config(
        issuers: [_issuer("pbdf", "cis", address: "https://stichtingcis.nl/")],
        requestors: {
          "inzage.stichtingcis.nl": RequestorInfo(
            id: "pbdf-requestors.cis",
            name: const TranslatedValue.empty(),
            hostnames: const ["inzage.stichtingcis.nl"],
          ),
        },
      ),
    )!;
    expect(org.website, Uri.parse("https://stichtingcis.nl/"));
  });

  test("requestor without an issuer: site from its hostname", () {
    final org = SupportParty.resolve(
      _party("pbdf-requestors.vgz"),
      _config(
        requestors: {
          "irma.vgz.nl": RequestorInfo(
            id: "pbdf-requestors.vgz",
            name: const TranslatedValue.empty(),
            hostnames: const ["irma.vgz.nl"],
          ),
        },
      ),
    )!;
    expect(org.website, Uri.https("vgz.nl"));
    expect(org.email, isNull);
  });

  test("no contact details at all", () {
    final org = SupportParty.resolve(_party("pbdf-requestors.x"), _config())!;
    expect(org.website, isNull);
    expect(org.email, isNull);
  });

  test("Yivi's own parties", () {
    for (final id in [
      "pbdf.pbdf",
      "pbdf.sidn-pbdf",
      "pbdf-requestors.pbdf",
      "pbdf-requestors.sidn-pbdf",
    ]) {
      expect(
        SupportParty.resolve(_party(id), _config())!.isYivi,
        isTrue,
        reason: id,
      );
    }
    final bySupportEmail = SupportParty.resolve(
      _party("other.issuer"),
      _config(issuers: [_issuer("other", "issuer", email: "support@yivi.app")]),
    )!;
    expect(bySupportEmail.isYivi, isTrue);
  });

  test("ignores no-reply addresses and non-web contact addresses", () {
    final org = SupportParty.resolve(
      _party("pbdf.minvws"),
      _config(
        issuers: [
          _issuer(
            "pbdf",
            "minvws",
            address: "Postbus 20011",
            email: "noreply+seecontactform@rijksoverheid.nl",
          ),
        ],
      ),
    )!;
    expect(org.website, isNull);
    expect(org.email, isNull);
  });

  test("siteOfHostname", () {
    expect(
      SupportParty.siteOfHostname("inzage.stichtingcis.nl"),
      Uri.https("stichtingcis.nl"),
    );
    expect(SupportParty.siteOfHostname("vgz.nl"), Uri.https("vgz.nl"));
    expect(SupportParty.siteOfHostname("localhost"), isNull);
  });

  test("siteOfHostname keeps a country's second level", () {
    expect(
      SupportParty.siteOfHostname("portal.example.co.uk"),
      Uri.https("example.co.uk"),
    );
    expect(
      SupportParty.siteOfHostname("login.example.com.au"),
      Uri.https("example.com.au"),
    );
    // A short Dutch domain is not a country's second level.
    expect(SupportParty.siteOfHostname("inzage.cis.nl"), Uri.https("cis.nl"));
  });

  test("siteOfHostname takes no IP address for a site", () {
    expect(SupportParty.siteOfHostname("192.168.1.10"), isNull);
    expect(SupportParty.siteOfHostname("10.0.0.1"), isNull);
  });

  test("directory: every organisation to search, once, by name", () {
    RequestorInfo requestor(String id, String name, String host) =>
        RequestorInfo(
          id: id,
          name: TranslatedValue({"nl": name, "en": name}),
          hostnames: [host],
          unverified: false,
        );

    final orgs = SupportParty.directory(
      _config(
        issuers: [
          // Covered by its requestor below.
          _issuer("pbdf", "cis", address: "https://stichtingcis.nl/"),
          // No requestor: listed as an issuer.
          Issuer(
            id: "nuts",
            name: TranslatedValue({"nl": "Nuts", "en": "Nuts"}),
            schemeManagerId: "pbdf",
            contactAddress: "https://nuts.nl",
            contactEmail: "",
          ),
          // Yivi's own: listed, and leads to Yivi support.
          Issuer(
            id: "sidn-pbdf",
            name: TranslatedValue({"nl": "Yivi", "en": "Yivi"}),
            schemeManagerId: "pbdf",
            contactAddress: "https://yivi.app",
            contactEmail: "support@yivi.app",
          ),
        ],
        requestors: {
          // One requestor, two hostnames.
          "inzage.stichtingcis.nl": requestor(
            "pbdf-requestors.cis",
            "Stichting CIS",
            "inzage.stichtingcis.nl",
          ),
          "yivi.stichtingcis.nl": requestor(
            "pbdf-requestors.cis",
            "Stichting CIS",
            "yivi.stichtingcis.nl",
          ),
          "irma.vgz.nl": requestor("pbdf-requestors.vgz", "VGZ", "irma.vgz.nl"),
          "demo.example.org": requestor(
            "irma-demo-requestors.demo",
            "Demo",
            "demo.example.org",
          ),
        },
        requestorSchemes: {
          "irma-demo-requestors": RequestorScheme(
            id: "irma-demo-requestors",
            demo: true,
          ),
        },
      ),
      "nl",
    );

    expect(orgs.map((o) => o.name), ["Nuts", "Stichting CIS", "VGZ", "Yivi"]);
    expect(orgs.last.isYivi, isTrue);
    expect(
      orgs.firstWhere((o) => o.name == "Stichting CIS").website,
      Uri.parse("https://stichtingcis.nl/"),
    );
  });

  group("a server that is not in the scheme", () {
    // irmago names it after its hostname and gives it no id.
    TrustedParty unknownServer(String hostname) => TrustedParty(
      id: "",
      name: hostname,
      url: null,
      parent: null,
      verified: false,
    );

    test("gets the site behind its hostname", () {
      final org = SupportParty.resolve(
        unknownServer("login.example.com"),
        _config(),
      )!;
      expect(org.website, Uri.https("example.com"));
      expect(org.isYivi, isFalse);
    });

    test("on an IP address has no site", () {
      final org = SupportParty.resolve(
        unknownServer("192.168.1.10"),
        _config(),
      )!;
      expect(org.website, isNull);
      expect(org.isYivi, isFalse);
    });

    test("is Yivi's when it runs on a Yivi domain", () {
      // The email issuer's sessions run on this server.
      final org = SupportParty.resolve(
        unknownServer("is.demo.staging.yivi.app"),
        _config(),
      )!;
      expect(org.website, Uri.https("yivi.app"));
      expect(org.isYivi, isTrue);
    });

    test("verified names are not taken for hostnames", () {
      final org = SupportParty.resolve(
        _party("pbdf-requestors.ver-id", name: "Ver.iD"),
        _config(),
      )!;
      expect(org.website, isNull);
    });

    test("is told apart by its hostname", () {
      expect(
        SupportParty.keyOf(unknownServer("a.example.com")),
        isNot(SupportParty.keyOf(unknownServer("b.example.com"))),
      );
      expect(
        SupportParty.keyOf(_party("pbdf-requestors.cis")),
        "pbdf-requestors.cis",
      );
    });
  });
}

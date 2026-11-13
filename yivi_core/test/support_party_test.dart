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
}) => IrmaConfiguration(
  schemeManagers: const {},
  requestorSchemes: const {},
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
}

import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/issuance_launcher.dart" show EmbeddedFlow;
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/models/credential_store.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/session_state.dart";
import "package:yivi_core/src/screens/session/models/issuance_view_model.dart";

TrustedParty _party(String name, {bool verified = true}) => TrustedParty(
  id: name,
  name: name,
  url: null,
  parent: null,
  verified: verified,
);

CredentialDescriptor _descriptor(
  String id, {
  List<Attribute> attributes = const [],
}) => CredentialDescriptor(
  credentialId: id,
  name: id,
  issuer: _party("Issuer"),
  category: null,
  attributes: attributes,
  issueURL: "https://www.issuer.example/get",
);

Credential _offered(
  String id,
  List<Attribute> attributes, {
  bool verified = true,
  bool singleton = false,
}) => Credential(
  credentialId: id,
  hash: "offered-$id",
  name: id,
  issuer: _party("Issuer", verified: verified),
  credentialInstanceIds: {CredentialFormat.idemix: "offered-$id"},
  batchInstanceCountsRemaining: const {},
  attributes: attributes,
  revoked: false,
  revocationSupported: false,
  issueUrl: null,
  isSingleton: singleton,
);

Attribute _string(String path, String value, {String? requested}) => Attribute(
  claimPath: [path],
  displayName: path,
  value: AttributeValue(type: AttributeType.string, string: value),
  requestedValue: requested == null
      ? null
      : AttributeValue(type: AttributeType.string, string: requested),
);

AttributeValue _value(String v) =>
    AttributeValue(type: AttributeType.string, string: v);

/// A request of "Webshop" that still needs an iDIN card and an iDEAL card
/// with BIC RABONL2U.
SessionState _request() => SessionState(
  id: 1,
  protocol: "irma",
  type: SessionType.disclosure,
  status: SessionStatus.requestPermission,
  requestor: _party("Webshop"),
  disclosurePlan: DisclosurePlan(
    choices: [
      _missing(_descriptor("idin")),
      _missing(
        _descriptor(
          "ideal",
          attributes: [_string("bic", "", requested: "RABONL2U")],
        ),
      ),
    ],
    issuedCredentialIds: const {},
  ),
);

/// A required choice whose one slot has no card and offers [d].
DisclosureChoice _missing(CredentialDescriptor d) => DisclosureChoice(
  optional: false,
  options: [
    DisclosureOption(
      slots: [
        DisclosureSlot(
          id: d.credentialId,
          candidates: const [],
          obtainable: [d],
        ),
      ],
    ),
  ],
);

final _bad = _offered("ideal", [_string("bic", "INGBNL2A")]);
final _good = _offered("ideal", [_string("bic", "RABONL2U")]);

void main() {
  group("the offer", () {
    test("on its own: add, no tags, nothing mismatched", () {
      final s = issuanceOfferOf([_bad], retryOnMismatch: true);
      expect(s.primary, IssuancePrimary.add);
      expect(s.link, isNull);
      expect(s.risky, isFalse);
      expect(s.mismatches, isEmpty);
      expect(s.note, isNull);
      expect(s.requestor, isNull);
      expect(s.issuer?.name, "Issuer");
      expect(s.perCard.single.tag, isNull);
      expect(s.perCard.single.mismatchedPaths, isEmpty);
    });

    test("nobody vouches for the issuer: add anyway", () {
      final s = issuanceOfferOf([
        _offered("email", const [], verified: false),
      ], retryOnMismatch: true);
      expect(s.risky, isTrue);
      expect(s.primary, IssuancePrimary.addAnyway);
      expect(s.link, isNull);
    });

    test("in the sheet a card with another value: Toch toevoegen", () {
      final s = issuanceOfferOf(
        [_bad],
        forRequest: _request(),
        retryOnMismatch: true,
      );
      expect(s.mismatched, isTrue);
      expect(s.note?.attributeName, "bic");
      expect(s.requestor?.name, "Webshop");
      expect(s.primary, IssuancePrimary.addOther);
      expect(s.link, IssuanceLink.dontAdd);
      expect(s.perCard.single.tag, OfferTag.notCounted);
      expect(s.perCard.single.mismatchedPaths, {'["bic"]'});
    });

    test("a card that replaces one: Toch vervangen", () {
      final s = issuanceOfferOf(
        [
          _offered("ideal", [_string("bic", "INGBNL2A")], singleton: true),
        ],
        forRequest: _request(),
        retryOnMismatch: true,
      );
      expect(s.primary, IssuancePrimary.replaceOther);
      expect(s.link, IssuanceLink.dontAdd);
    });

    test("full screen a card that does not count: still add", () {
      final s = issuanceOfferOf(
        [_bad],
        forRequest: _request(),
        retryOnMismatch: false,
      );
      expect(s.mismatched, isTrue);
      expect(s.note, isNotNull);
      expect(s.primary, IssuancePrimary.add);
      expect(s.link, isNull);
    });

    test("a mismatch is never risky, even from an issuer nobody vouches", () {
      final s = issuanceOfferOf(
        [
          _offered("ideal", [_string("bic", "INGBNL2A")], verified: false),
        ],
        forRequest: _request(),
        retryOnMismatch: true,
      );
      expect(s.risky, isFalse);
      expect(s.primary, IssuancePrimary.addOther);
    });

    test("several cards in a request: asked and comes too", () {
      final s = issuanceOfferOf(
        [_good, _offered("email", const [])],
        forRequest: _request(),
        retryOnMismatch: true,
      );
      expect(s.primary, IssuancePrimary.add);
      expect(
        [for (final c in s.perCard) c.tag],
        [OfferTag.asked, OfferTag.comesToo],
      );
    });

    test("one card in a request that counts: no tag", () {
      final s = issuanceOfferOf(
        [_good],
        forRequest: _request(),
        retryOnMismatch: true,
      );
      expect(s.perCard.single.tag, isNull);
    });
  });

  group("the plan of adding a card", () {
    test("the steps and the intro per flow", () {
      final email = issuePlanOf(
        _descriptor("pbdf.sidn-pbdf.email"),
        EmbeddedFlow.email,
      );
      expect(email.total(), 4);
      expect(email.howIntroKey, "data.add.details.how_email");
      final phone = issuePlanOf(
        _descriptor("pbdf.sidn-pbdf.mobilenumber"),
        EmbeddedFlow.phone,
      );
      expect(phone.total(), 4);
      expect(phone.howIntroKey, "data.add.details.how_phone");
      final website = issuePlanOf(_descriptor("pbdf.gemeente.address"), null);
      expect(website.total(), 3);
      expect(website.howIntroKey, isNull);
    });

    test("a document: 5 steps, or its flow's own count once started", () {
      final passport = issuePlanOf(
        _descriptor("pbdf.pbdf.passport"),
        EmbeddedFlow.document,
      );
      expect(passport.document, isNotNull);
      expect(passport.total(), 5);
      expect(passport.total(documentTotal: 6), 6);
      expect(passport.howIntroKey, "data.add.details.how_document");
    });

    test("a document flow for a card that is no document: as a website", () {
      final other = issuePlanOf(
        _descriptor("pbdf.pbdf.other"),
        EmbeddedFlow.document,
      );
      expect(other.document, isNull);
      expect(other.total(documentTotal: 6), 3);
      expect(other.howIntroKey, isNull);
    });
  });

  group("a value the request cannot use", () {
    final steps = [
      _descriptor("idin"),
      _descriptor(
        "ideal",
        attributes: [_string("bic", "", requested: "RABONL2U")],
      ),
    ];

    test("an offered value that differs from the requested one", () {
      final mismatches = issuanceMismatches([
        _offered("ideal", [_string("bic", "INGBNL2A")]),
      ], steps);
      expect(mismatches, hasLength(1));
      expect(mismatches.single.attributeName, "bic");
      expect(mismatches.single.offered?.string, "INGBNL2A");
      expect(mismatches.single.required.string, "RABONL2U");
    });

    test("a matching value is no mismatch", () {
      expect(
        issuanceMismatches([
          _offered("ideal", [_string("bic", "RABONL2U")]),
        ], steps),
        isEmpty,
      );
    });

    test("any of several allowed values is no mismatch", () {
      final anyOf = CredentialDescriptor(
        credentialId: "ideal",
        name: "iDEAL",
        issuer: _party("Issuer"),
        category: null,
        attributes: [
          Attribute(
            claimPath: const ["bic"],
            displayName: "bic",
            requestedValue: _value("RABONL2U"),
            requestedValues: [_value("RABONL2U"), _value("INGBNL2A")],
          ),
        ],
        issueURL: "https://issuer",
      );
      expect(
        issuanceMismatches(
          [
            _offered("ideal", [_string("bic", "INGBNL2A")]),
          ],
          [anyOf],
        ),
        isEmpty,
      );
      final mismatches = issuanceMismatches(
        [
          _offered("ideal", [_string("bic", "ABNANL2A")]),
        ],
        [anyOf],
      );
      expect(mismatches.single.required.string, "RABONL2U");
    });
  });
}

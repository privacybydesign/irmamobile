import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/screens/activity/activity_entry.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/card_art_support.dart";

import "helpers/credential_factory.dart";

// The large card at the top of an activity entry shows what was shared;
// what was not is a smear, and the real value never goes into the picture.

LogCredential _logged(List<Attribute> attributes) => LogCredential(
  credentialId: "pbdf.gemeente.address",
  formats: const [CredentialFormat.idemix],
  name: "Address",
  issuer: TrustedParty(
    id: "gemeente",
    name: "Gemeente",
    url: null,
    parent: null,
    verified: true,
  ),
  attributes: attributes,
  revoked: false,
  revocationSupported: false,
  hash: "address",
);

void main() {
  group("obscureHiddenValues", () {
    test("a value in a text: a faint smear in the text's colour", () {
      final svg = fillSvgTemplate(
        '<svg><text x="20" y="40" font-size="20" fill="#FFFFFF">'
        "<tspan>{{street}}</tspan> <tspan>{{houseNumber}}</tspan></text></svg>",
        {"street": "Meander", "houseNumber": hiddenValueMark("501")},
      );
      final out = obscureHiddenValues(svg);
      expect(out, contains("Meander"));
      expect(out, isNot(contains("501")));
      expect(out, contains('stroke="#FFFFFF"'));
      expect(out, contains('stroke-width="16.0"'));
      // At least four letters long, whatever the value's length.
      expect(out, contains(">oooo</tspan>"));
      expect(out, isNot(contains("\uE000")));
    });

    test("a photo: a faint block in its place", () {
      final svg = fillSvgTemplate(
        '<svg><image href="{{photo}}" x="20" y="72" width="66" height="84"/>'
        "</svg>",
        {"photo": hiddenValueMark("data:image/png;base64,AAAA")},
      );
      final out = obscureHiddenValues(svg);
      expect(out, isNot(contains("<image")));
      expect(out, isNot(contains("base64")));
      expect(
        out,
        contains(
          '<rect x="20" y="72" width="66" height="84" rx="6" '
          'fill="#8A8F98" fill-opacity="0.35"/>',
        ),
      );
    });

    test("a template without hidden values is left as it is", () {
      const svg = '<svg><text fill="#000">Jan</text></svg>';
      expect(obscureHiddenValues(svg), svg);
    });
  });

  group("ActivityEntryCard", () {
    final wallet = testCredential(
      type: "pbdf.gemeente.address",
      hash: "address",
      name: "Address",
      attributes: [
        stringAttr("street", "Kade"),
        stringAttr("houseNumber", "12"),
        stringAttr("city", "Almere"),
      ],
    );

    test("shared: what did not go along is obscured, the rest as logged", () {
      final card = ActivityEntryCard(
        credential: _logged([stringAttr("city", "Amsterdam")]),
        role: ActivityRole.shared,
        art: wallet,
      );
      expect(card.unshared, {
        Attribute.pathKey(["street"]),
        Attribute.pathKey(["houseNumber"]),
      });
      final city = card.heroArt.attributes.singleWhere(
        (a) => a.claimPath.last == "city",
      );
      // As it was shared, not as the card has it now.
      expect(city.value?.string, "Amsterdam");
    });

    test("received: nothing obscured, the card as it is", () {
      final card = ActivityEntryCard(
        credential: _logged([stringAttr("city", "Amsterdam")]),
        role: ActivityRole.received,
        art: wallet,
      );
      expect(card.unshared, isEmpty);
      expect(card.heroArt, same(wallet));
    });
  });
}

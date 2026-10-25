import "package:flutter_test/flutter_test.dart";

import "package:yivi_core/src/providers/credential_field_search.dart";

SearchField _f(String label, [String? value]) =>
    SearchField(claimKey: label, label: label, value: value);

List<String> _labels(List<FieldHit> hits) =>
    hits.map((h) => h.field.label).toList();

void main() {
  group("matchFields — word prefix", () {
    test("a value is found from the start of any word", () {
      final hits = matchFields([
        _f("Woonplaats", "Utrecht"),
        _f("E-mailadres", "a.devries@utrecht.nl"),
        _f("Straat", "Oudegracht"),
      ], "utrecht");
      expect(_labels(hits), ["Woonplaats", "E-mailadres"]);
      expect(hits.every((h) => h.kind == FieldHitKind.value), isTrue);
      expect(hits[1].match, const SearchMatch(10, 17));
    });

    test("not from the middle of a word", () {
      expect(matchFields([_f("E-mailadres", "x@y.nl")], "adres"), isEmpty);
      expect(matchFields([_f("Voornamen", "Hanna")], "anna"), isEmpty);
    });

    test("no typos on fields", () {
      expect(matchFields([_f("Woonplaats", "Utrecht")], "utrcht"), isEmpty);
    });

    test("a label matches; the value does not need to", () {
      final hits = matchFields([_f("BSN", "999999990")], "bsn");
      expect(hits.single.kind, FieldHitKind.label);
      expect(hits.single.match, const SearchMatch(0, 3));
    });

    test("a label match wins over a value match on the same field", () {
      final hits = matchFields([_f("Naam", "Naamloos")], "naam");
      expect(hits.single.kind, FieldHitKind.label);
    });

    test("hyphens: typed or left out", () {
      expect(
        matchFields([_f("E-mailadres", "a@b.nl")], "e-mail").single.match,
        const SearchMatch(0, 6),
      );
      // Left out: the whole label is the match.
      expect(
        matchFields([_f("E-mailadres", "a@b.nl")], "email").single.match,
        const SearchMatch(0, 11),
      );
    });
  });

  group("matchFields — minimum lengths", () {
    test("labels from 2 characters", () {
      expect(matchFields([_f("BSN", "1")], "b"), isEmpty);
      expect(matchFields([_f("BSN", "1")], "bs"), hasLength(1));
    });

    test("values from 3 characters", () {
      expect(matchFields([_f("Woonplaats", "Utrecht")], "ut"), isEmpty);
      expect(matchFields([_f("Woonplaats", "Utrecht")], "utr"), hasLength(1));
    });

    test("a field without a searchable value is found by its label only", () {
      expect(matchFields([_f("Over 18")], "ja"), isEmpty);
      expect(matchFields([_f("Over 18")], "over"), hasLength(1));
    });
  });

  group("matchFields — folding", () {
    test("diacritics fold, and the match covers the original text", () {
      final hit = matchFields([_f("Categorieën", "B")], "categorieen").single;
      expect(hit.match, const SearchMatch(0, 11));
    });

    test("ß matches ss and marks the one character", () {
      final hit = matchFields([_f("Straße", "x")], "strass").single;
      expect(hit.match, const SearchMatch(0, 5));
    });

    test("case and surrounding spaces don't matter", () {
      expect(
        matchFields([_f("Woonplaats", "Utrecht")], "  UTRECHT "),
        hasLength(1),
      );
    });
  });

  group("rankCards", () {
    final fields = {
      "pers": [_f("BSN", "999999990"), _f("Voornamen", "Anna")],
      "adres": [_f("Woonplaats", "Utrecht")],
      "stud": [_f("Naam", "Anna de Vries")],
      "mail": [_f("E-mailadres", "anna@utrecht.nl")],
    };
    const order = ["pers", "adres", "stud", "mail"];

    test("name hits first, then label hits, then value hits", () {
      final r = rankCards(
        order: order,
        byName: ["stud"],
        fields: fields,
        query: "utrecht",
      );
      expect(r.map((c) => c.hash), ["stud", "adres", "mail"]);
      expect(r.first.byName, isTrue);
      expect(r[1].byName, isFalse);
    });

    test("a card found by a label comes before one found by a value", () {
      final r = rankCards(
        order: const ["mail", "pers"],
        byName: const [],
        fields: {
          "mail": [_f("Notitie", "bsn staat hier")],
          "pers": [_f("BSN", "1")],
        },
        query: "bsn",
      );
      expect(r.map((c) => c.hash), ["pers", "mail"]);
    });

    test("value hits keep the card order", () {
      final r = rankCards(
        order: order,
        byName: const [],
        fields: fields,
        query: "anna",
      );
      expect(r.map((c) => c.hash), ["pers", "stud", "mail"]);
    });

    test("a name hit keeps its field hits for the detail screen", () {
      final r = rankCards(
        order: order,
        byName: ["pers"],
        fields: fields,
        query: "bsn",
      );
      expect(r.single.byName, isTrue);
      expect(r.single.hits.single.field.label, "BSN");
    });
  });
}

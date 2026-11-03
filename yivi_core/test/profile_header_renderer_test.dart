import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart"
    as schemaless;
import "package:yivi_core/src/widgets/credential_card/attribute_groups/attribute_comparison.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/attribute_group.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/profile_header/profile_header_renderer.dart";

// A valid 1x1 PNG.
const _png =
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC";

schemaless.Attribute _str(String id, String value) => schemaless.Attribute(
  claimPath: [id],
  displayName: id,
  value: schemaless.AttributeValue(
    type: schemaless.AttributeType.string,
    string: value,
  ),
);

schemaless.Attribute _bool(String id, bool value) => schemaless.Attribute(
  claimPath: [id],
  displayName: id,
  value: schemaless.AttributeValue(
    type: schemaless.AttributeType.boolean,
    boolValue: value,
  ),
);

schemaless.Attribute _photo(String base64) => schemaless.Attribute(
  claimPath: ["photo"],
  displayName: "Photo",
  value: schemaless.AttributeValue(
    type: schemaless.AttributeType.base64Image,
    base64Image: base64,
  ),
);

List<String> _ids(List<schemaless.Attribute> attrs) =>
    [for (final a in attrs) a.claimPath.first as String]..sort();

const _documents = ProfileHeaderRenderer(DocumentProfileAdapter());
const _municipality = ProfileHeaderRenderer(MunicipalityProfileAdapter());

ProfileHeaderView _view(
  ProfileHeaderAdapter adapter,
  List<schemaless.Attribute> attrs, {
  List<schemaless.Attribute>? compareTo,
}) => adapter.viewOf(attrs, compareTo: compareTo);

void main() {
  group("documents", () {
    final passport = [
      _photo(_png),
      _str("documentNumber", "X1234567"),
      _str("firstName", "Anna"),
      _str("lastName", "de Vries"),
      _str("nationality", "NLD"),
      _str("dateOfBirth", "1996-12-17"),
      _str("yearOfBirth", "1996"),
      _str("gender", "F"),
      _bool("over18", true),
    ];

    test("full passport: photo, name and details, as given", () {
      final view = _view(const DocumentProfileAdapter(), passport);
      expect(view.photo, isNotNull);
      expect(view.name?.text, "Anna de Vries");
      expect(view.dateOfBirth?.text, "1996-12-17");
      expect(view.nationality?.text, "NLD");
      expect(view.gender?.text, "F");
      expect(view.placeOfBirth, isNull, reason: "passports have none");
    });

    test("claims exactly what it shows, at the top", () {
      final group = _documents.claim(passport)!;
      expect(group.placement, isA<TopPlacement>());
      expect(_ids(group.claimed), [
        "dateOfBirth",
        "firstName",
        "gender",
        "lastName",
        "nationality",
        "over18",
        "photo",
      ]);
    });

    test("ages become chips, sorted; EU citizen only when yes", () {
      final view = _view(const DocumentProfileAdapter(), [
        _str("lastName", "de Vries"),
        _bool("over65", false),
        _str("over12", "yes"),
        _bool("over21", true),
        _bool("isEuCitizen", true),
      ]);
      expect(
        [for (final e in view.ages.entries) (e.age, e.over)],
        [(12, true), (21, true), (65, false)],
      );
      expect(_ids(view.ages.sources), ["over12", "over21", "over65"]);
      expect(view.euCitizen?.claimPath, ["isEuCitizen"]);

      final notEu = _view(const DocumentProfileAdapter(), [
        _str("lastName", "de Vries"),
        _str("isEuCitizen", "no"),
      ]);
      expect(notEu.euCitizen, isNull, reason: "a no stays a field");
      expect(_ids(notEu.claimed), ["lastName"]);
    });

    test("comparing: no age or EU chips, each keeps its own row", () {
      final attrs = [
        _str("lastName", "de Vries"),
        _bool("over18", true),
        _bool("isEuCitizen", true),
      ];
      final view = _view(
        const DocumentProfileAdapter(),
        attrs,
        compareTo: attrs,
      );
      expect(view.ages.entries, isEmpty);
      expect(view.euCitizen, isNull);
      expect(_ids(view.claimed), ["lastName"]);
    });

    test("driving licence: place of birth", () {
      final view = _view(const DocumentProfileAdapter(), [
        _str("firstName", "Anna"),
        _str("lastName", "de Vries"),
        _str("placeOfBirth", "Meppel"),
      ]);
      expect(view.placeOfBirth?.text, "Meppel");
    });

    test("no photo, or an unusable one: no photo", () {
      expect(
        _view(const DocumentProfileAdapter(), [_str("lastName", "x")]).photo,
        isNull,
      );
      expect(
        _view(const DocumentProfileAdapter(), [
          _photo(" "),
          _str("lastName", "x"),
        ]).photo,
        isNull,
      );
    });

    test("empty values are absent and not claimed", () {
      final group = _documents.claim([
        _str("firstName", "Anna"),
        _str("lastName", ""),
        _str("gender", ""),
      ])!;
      expect(_ids(group.claimed), ["firstName"]);
    });
  });

  group("threshold: name or photo", () {
    test("over18 only: nothing claimed", () {
      expect(_documents.claim([_bool("over18", true)]), isNull);
    });

    test("date of birth only: nothing claimed", () {
      expect(_documents.claim([_str("dateOfBirth", "1996-12-17")]), isNull);
    });

    test("part of the name: a header", () {
      final group = _documents.claim([
        _str("lastName", "de Vries"),
        _str("nationality", "NLD"),
      ])!;
      expect(_ids(group.claimed), ["lastName", "nationality"]);
    });

    test("photo only: a header", () {
      final group = _documents.claim([_photo(_png)])!;
      expect(_ids(group.claimed), ["photo"]);
    });
  });

  group("municipality", () {
    final personalData = [
      _str("initials", "A."),
      _str("firstnames", "Anna"),
      _str("prefix", "de"),
      _str("familyname", "Vries"),
      // As the municipality issues it: the surname with its prefix.
      _str("surname", "de Vries-Jansen"),
      _str("gender", "V"),
      _bool("nationality", true),
      _str("dateofbirth", "17-12-1996"),
      _str("cityofbirth", "Meppel"),
      _str("countryofbirth", "Nederland"),
      _str("bsn", "999999990"),
    ];

    test("first names + surname (Voornamen + Achternaam)", () {
      final view = _view(const MunicipalityProfileAdapter(), personalData);
      expect(view.name?.text, "Anna de Vries-Jansen");
      expect(view.placeOfBirth?.text, "Meppel, Nederland");
      expect(
        view.nationality?.translationKey,
        "credential.profile_header.dutch",
      );
      expect(view.photo, isNull);
    });

    test("never claims initials, the birth name or the BSN", () {
      final claimed = _ids(_municipality.claim(personalData)!.claimed);
      expect(claimed, isNot(contains("initials")));
      expect(claimed, isNot(contains("familyname")));
      expect(claimed, isNot(contains("bsn")));
      expect(claimed, isNot(contains("prefix")), reason: "in the surname");
      expect(claimed, containsAll(["firstnames", "surname"]));
    });

    test("with fullname: the parts shown, the full name taken unshown", () {
      final attrs = [_str("fullname", "A. de Vries-Jansen"), ...personalData];
      final view = _view(const MunicipalityProfileAdapter(), attrs);
      expect(view.name?.text, "Anna de Vries-Jansen");
      expect(_ids(view.redundant), ["fullname"]);
      final claimed = _ids(_municipality.claim(attrs)!.claimed);
      expect(claimed, containsAll(["fullname", "firstnames", "surname"]));
    });

    test("only the full name (a disclosure): the full name shown", () {
      final view = _view(const MunicipalityProfileAdapter(), [
        _str("fullname", "A. de Vries-Jansen"),
        _str("surname", "de Vries-Jansen"),
      ]);
      expect(view.name?.text, "A. de Vries-Jansen");
      expect(view.redundant, isEmpty);
      expect(_ids(view.claimed), ["fullname"]);
    });

    test("Dutch nationality: yes shown, no stays a row", () {
      expect(
        _view(const MunicipalityProfileAdapter(), [
          _str("surname", "x"),
          _str("nationality", "Ja"),
        ]).nationality,
        isNotNull,
      );
      final no = _municipality.claim([
        _str("surname", "x"),
        _bool("nationality", false),
      ])!;
      expect(_ids(no.claimed), ["surname"]);
    });

    test("place of birth from one part", () {
      final view = _view(const MunicipalityProfileAdapter(), [
        _str("surname", "x"),
        _str("countryofbirth", "Nederland"),
      ]);
      expect(view.placeOfBirth?.text, "Nederland");
    });
  });

  group("compareTo", () {
    test("a composed name mismatches when any part does", () {
      final attrs = [_str("firstName", "Anna"), _str("lastName", "de Vries")];
      final view = _view(
        const DocumentProfileAdapter(),
        attrs,
        compareTo: [_str("firstName", "Anna"), _str("lastName", "Jansen")],
      );
      expect(view.name?.comparison, AttributeComparison.mismatch);
    });

    test("all parts matching is a match", () {
      final attrs = [_str("firstName", "Anna"), _str("lastName", "de Vries")];
      final view = _view(
        const DocumentProfileAdapter(),
        attrs,
        compareTo: attrs,
      );
      expect(view.name?.comparison, AttributeComparison.match);
    });
  });
}

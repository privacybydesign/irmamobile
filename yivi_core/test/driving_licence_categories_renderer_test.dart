import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart"
    as schemaless;
import "package:yivi_core/src/widgets/credential_card/attribute_groups/attribute_group.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/driving_licence/driving_licence_categories_renderer.dart";

schemaless.Attribute _str(String id, String? value) => schemaless.Attribute(
  claimPath: [id],
  displayName: id,
  value: schemaless.AttributeValue(
    type: schemaless.AttributeType.string,
    string: value,
  ),
);

schemaless.Attribute _bool(String id, bool? value) => schemaless.Attribute(
  claimPath: [id],
  displayName: id,
  value: schemaless.AttributeValue(
    type: schemaless.AttributeType.boolean,
    boolValue: value,
  ),
);

/// All 48 category attributes as the issuer sends them, with [held] mapping a
/// held code to its (issued, expires) dates.
List<schemaless.Attribute> _all(Map<String, (String, String)> held) => [
  for (final code in DrivingLicenceCategoriesRenderer.codes) ...[
    _bool("category$code", held.containsKey(code)),
    _str("category${code}DateOfIssue", held[code]?.$1),
    _str("category${code}DateOfExpiry", held[code]?.$2),
  ],
];

/// The 48 attributes of a licence whose chip held no category data.
List<schemaless.Attribute> _allEmpty() => [
  for (final code in DrivingLicenceCategoriesRenderer.codes) ...[
    _bool("category$code", null),
    _str("category${code}DateOfIssue", null),
    _str("category${code}DateOfExpiry", null),
  ],
];

const _renderer = DrivingLicenceCategoriesRenderer();

DrivingLicenceCategoriesView _view(
  List<schemaless.Attribute> attrs, {
  List<schemaless.Attribute>? compareTo,
}) {
  final group = _renderer.claim(attrs, compareTo: compareTo)!;
  return DrivingLicenceCategoriesRenderer.viewOf(
    group.claimed,
    compareTo: compareTo,
  );
}

void main() {
  test("claims every category attribute and nothing else", () {
    final others = [
      _str("firstName", "Anna"),
      _str("dateOfExpiry", "2030-01-01"),
      _str("categoryX", "yes"), // unknown code
      _str("category", "yes"),
    ];
    final categories = _all({"B": ("2015-03-01", "2030-03-01")});
    final group = _renderer.claim([...others, ...categories])!;

    expect(group.claimed, hasLength(48));
    expect(group.claimed, containsAll(categories));
    expect(group.claimed.where(others.contains), isEmpty);
    expect(group.placement, isA<AfterPlacement>());
    expect((group.placement as AfterPlacement).attributeId, "dateOfExpiry");
  });

  test("claims nothing when there are no category attributes", () {
    expect(_renderer.claim([_str("firstName", "Anna")]), isNull);
  });

  test("full credential: held categories as rows, the rest not held", () {
    final view = _view(
      _all({
        "AM": ("2010-01-01", "2030-01-01"),
        "B": ("2015-03-01", "2030-03-01"),
      }),
    );

    expect(view.noInformation, isFalse);
    expect(view.held.map((r) => r.code), ["AM", "B"]);
    final b = view.held[1];
    expect(b.held?.value, isTrue);
    expect(b.issued?.value, "2015-03-01");
    expect(b.expires?.value, "2030-03-01");
    expect(b.held?.comparison, AttributeComparison.none);
    expect(
      view.notHeld.map((c) => c.value),
      DrivingLicenceCategoriesRenderer.codes.where(
        (c) => c != "AM" && c != "B",
      ),
    );
  });

  test("all categories explicitly not held", () {
    final view = _view(_all({}));
    expect(view.held, isEmpty);
    expect(view.notHeld, hasLength(16));
  });

  test("chip without category data shows no information", () {
    final view = _view(_allEmpty());
    expect(view.noInformation, isTrue);
    expect(view.held, isEmpty);
    expect(view.notHeld, isEmpty);
  });

  test("disclosure of only the held flag", () {
    final view = _view([_bool("categoryB", true)]);
    expect(view.held.single.code, "B");
    expect(view.held.single.issued, isNull);
    expect(view.held.single.expires, isNull);
    expect(view.notHeld, isEmpty);
  });

  test("disclosure of only an expiry date: row without held marker", () {
    final view = _view([_str("categoryBDateOfExpiry", "2030-03-01")]);
    final row = view.held.single;
    expect(row.code, "B");
    expect(row.held, isNull);
    expect(row.issued, isNull);
    expect(row.expires?.value, "2030-03-01");
  });

  test("disclosure of a single not-held category", () {
    final view = _view([_bool("categoryC", false)]);
    expect(view.held, isEmpty);
    expect(view.notHeld.single.value, "C");
  });

  test("yes/no that irmago left as a string is understood", () {
    final view = _view([_str("categoryB", "yes"), _str("categoryC", "no")]);
    expect(view.held.single.code, "B");
    expect(view.notHeld.single.value, "C");
  });

  group("compareTo", () {
    test("matching values compare as match", () {
      final attrs = [
        _bool("categoryB", true),
        _str("categoryBDateOfExpiry", "2030-03-01"),
      ];
      final row = _view(attrs, compareTo: attrs).held.single;
      expect(row.held?.comparison, AttributeComparison.match);
      expect(row.expires?.comparison, AttributeComparison.match);
    });

    test("differing values compare as mismatch", () {
      final row = _view(
        [_bool("categoryB", true)],
        compareTo: [_bool("categoryB", false)],
      ).held.single;
      expect(row.held?.comparison, AttributeComparison.mismatch);
    });

    test("value missing from compareTo is a mismatch", () {
      final view = _view(
        [_bool("categoryB", true), _bool("categoryC", false)],
        compareTo: [_bool("categoryB", true)],
      );
      expect(view.held.single.held?.comparison, AttributeComparison.match);
      expect(view.notHeld.single.comparison, AttributeComparison.mismatch);
    });
  });
}

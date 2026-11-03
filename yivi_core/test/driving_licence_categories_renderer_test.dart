import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart"
    as schemaless;
import "package:yivi_core/src/widgets/credential_card/attribute_groups/attribute_comparison.dart";
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
    expect(group.placement, isA<EndPlacement>());
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
    // Every category gets a row, in licence-card order.
    expect(
      view.rows.map((r) => r.code),
      DrivingLicenceCategoriesRenderer.codes,
    );
    final held = view.rows.where((r) => !r.notHeld).toList();
    expect(held.map((r) => r.code), ["AM", "B"]);
    final b = held[1];
    expect(b.held?.value, isTrue);
    expect(b.issued?.value, "2015-03-01");
    expect(b.expires?.value, "2030-03-01");
    expect(b.held?.comparison, AttributeComparison.none);
    final c = view.rows.firstWhere((r) => r.code == "C");
    expect(c.notHeld, isTrue);
    expect(c.held?.value, isFalse);
    expect(c.issued, isNull);
    expect(c.expires, isNull);
  });

  test("all categories explicitly not held", () {
    final view = _view(_all({}));
    expect(view.rows, hasLength(16));
    expect(view.rows.every((r) => r.notHeld), isTrue);
  });

  test("chip without category data shows no information", () {
    final view = _view(_allEmpty());
    expect(view.noInformation, isTrue);
    expect(view.rows, isEmpty);
  });

  group("as the issuer now issues: every attribute, empty when unknown", () {
    // irmago delivers an empty yes/no attribute as an empty string.
    test("chip without category data: all empty strings", () {
      final view = _view([
        for (final code in DrivingLicenceCategoriesRenderer.codes) ...[
          _str("category$code", ""),
          _str("category${code}DateOfIssue", ""),
          _str("category${code}DateOfExpiry", ""),
        ],
      ]);
      expect(view.noInformation, isTrue);
    });

    test("not held: no, with empty dates", () {
      final view = _view([
        _bool("categoryD", false),
        _str("categoryDDateOfIssue", ""),
        _str("categoryDDateOfExpiry", ""),
      ]);
      final d = view.rows.single;
      expect(d.notHeld, isTrue);
      expect(d.issued, isNull);
      expect(d.expires, isNull);
    });

    test("held with an empty issue date", () {
      final view = _view([
        _bool("categoryB", true),
        _str("categoryBDateOfIssue", ""),
        _str("categoryBDateOfExpiry", "2030-03-01"),
      ]);
      final b = view.rows.single;
      expect(b.notHeld, isFalse);
      expect(b.issued, isNull);
      expect(b.expires?.value, "2030-03-01");
    });
  });

  test("disclosure of only the held flag", () {
    final view = _view([_bool("categoryB", true)]);
    final row = view.rows.single;
    expect(row.code, "B");
    expect(row.notHeld, isFalse);
    expect(row.issued, isNull);
    expect(row.expires, isNull);
  });

  test("disclosure of only an expiry date: row without held marker", () {
    final view = _view([_str("categoryBDateOfExpiry", "2030-03-01")]);
    final row = view.rows.single;
    expect(row.code, "B");
    expect(row.held, isNull);
    expect(row.issued, isNull);
    expect(row.expires?.value, "2030-03-01");
    expect(row.notHeld, isFalse, reason: "dates not given, not 'not held'");
  });

  test("disclosure of a single not-held category", () {
    final view = _view([_bool("categoryC", false)]);
    expect(view.rows.single.code, "C");
    expect(view.rows.single.notHeld, isTrue);
  });

  test("yes/no that irmago left as a string is understood", () {
    final view = _view([_str("categoryB", "yes"), _str("categoryC", "no")]);
    expect(view.rows.map((r) => (r.code, r.notHeld)), [
      ("B", false),
      ("C", true),
    ]);
  });

  group("compareTo", () {
    test("matching values compare as match", () {
      final attrs = [
        _bool("categoryB", true),
        _str("categoryBDateOfExpiry", "2030-03-01"),
      ];
      final row = _view(attrs, compareTo: attrs).rows.single;
      expect(row.held?.comparison, AttributeComparison.match);
      expect(row.expires?.comparison, AttributeComparison.match);
    });

    test("differing values compare as mismatch", () {
      final row = _view(
        [_bool("categoryB", true)],
        compareTo: [_bool("categoryB", false)],
      ).rows.single;
      expect(row.held?.comparison, AttributeComparison.mismatch);
    });

    test("value missing from compareTo is a mismatch", () {
      final view = _view(
        [_bool("categoryB", true), _bool("categoryC", false)],
        compareTo: [_bool("categoryB", true)],
      );
      expect(view.rows[0].held?.comparison, AttributeComparison.match);
      expect(view.rows[1].held?.comparison, AttributeComparison.mismatch);
    });
  });
}

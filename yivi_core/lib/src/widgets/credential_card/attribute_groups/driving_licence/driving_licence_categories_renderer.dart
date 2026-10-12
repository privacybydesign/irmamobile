import "package:collection/collection.dart";
import "package:flutter/foundation.dart";

import "../../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../attribute_group.dart";
import "driving_licence_categories_table.dart";

/// Draws the driving licence category attributes (`categoryX`,
/// `categoryXDateOfIssue`, `categoryXDateOfExpiry`) as one table.
class DrivingLicenceCategoriesRenderer implements AttributeGroupRenderer {
  const DrivingLicenceCategoriesRenderer();

  /// The categories the credential type defines, in the order of the licence
  /// card: the EU model's rows (Directive 2006/126/EC, Annex I) plus the
  /// Dutch T. B1 is printed on every EU licence but not issued in the
  /// Netherlands (RDW).
  static const codes = [
    "AM",
    "A1",
    "A2",
    "A",
    "B1",
    "B",
    "C1",
    "C",
    "D1",
    "D",
    "BE",
    "C1E",
    "CE",
    "D1E",
    "DE",
    "T",
  ];
  static const _issueSuffix = "DateOfIssue";
  static const _expirySuffix = "DateOfExpiry";

  @override
  AttributeGroup? claim(
    List<schemaless.Attribute> available, {
    List<schemaless.Attribute>? compareTo,
  }) {
    final claimed = available.where((a) => _match(a) != null).toList();
    if (claimed.isEmpty) return null;

    final view = viewOf(claimed, compareTo: compareTo);
    return AttributeGroup(
      claimed: claimed,
      placement: const AttributeGroupPlacement.after("dateOfExpiry"),
      build: (_) => DrivingLicenceCategoriesTable(view: view),
    );
  }

  /// What the table shows for the claimed category attributes.
  @visibleForTesting
  static DrivingLicenceCategoriesView viewOf(
    List<schemaless.Attribute> claimed, {
    List<schemaless.Attribute>? compareTo,
  }) {
    final byCode = <String, _CategoryAttributes>{};
    for (final attribute in claimed) {
      final (code, field) = _match(attribute)!;
      final entry = byCode.putIfAbsent(code, _CategoryAttributes.new);
      switch (field) {
        case _Field.held:
          entry.held = attribute;
        case _Field.issued:
          entry.issued = attribute;
        case _Field.expires:
          entry.expires = attribute;
      }
    }

    final allEmpty = byCode.values.every((c) => c.isEmpty);
    if (allEmpty) return const DrivingLicenceCategoriesView.noInformation();

    final held = <CategoryRow>[];
    final notHeld = <CompareValue<String>>[];
    for (final code in codes) {
      final c = byCode[code];
      if (c == null) continue;
      final heldFlag = _bool(c.held?.value);
      final issued = _string(c.issued?.value);
      final expires = _string(c.expires?.value);

      if (heldFlag == true || issued != null || expires != null) {
        held.add(
          CategoryRow(
            code: code,
            held: c.held == null
                ? null
                : CompareValue(heldFlag, _compare(c.held!, compareTo)),
            issued: issued == null
                ? null
                : CompareValue(issued, _compare(c.issued!, compareTo)),
            expires: expires == null
                ? null
                : CompareValue(expires, _compare(c.expires!, compareTo)),
          ),
        );
      } else if (c.held != null) {
        // An explicit "no", or an empty held flag, which we read as not held.
        notHeld.add(CompareValue(code, _compare(c.held!, compareTo)));
      }
    }
    return DrivingLicenceCategoriesView(held: held, notHeld: notHeld);
  }

  static (String, _Field)? _match(schemaless.Attribute attribute) {
    final path = attribute.claimPath;
    if (path.length != 1 || path.first is! String) return null;
    final id = path.first as String;
    if (!id.startsWith("category")) return null;
    var rest = id.substring("category".length);
    var field = _Field.held;
    if (rest.endsWith(_issueSuffix)) {
      rest = rest.substring(0, rest.length - _issueSuffix.length);
      field = _Field.issued;
    } else if (rest.endsWith(_expirySuffix)) {
      rest = rest.substring(0, rest.length - _expirySuffix.length);
      field = _Field.expires;
    }
    return codes.contains(rest) ? (rest, field) : null;
  }

  static bool? _bool(schemaless.AttributeValue? v) {
    if (v == null) return null;
    if (v.boolValue != null) return v.boolValue;
    // irmago falls back to a string when a yesno value is neither yes nor no.
    return switch (v.string?.toLowerCase()) {
      "yes" => true,
      "no" => false,
      _ => null,
    };
  }

  static String? _string(schemaless.AttributeValue? v) {
    final s = v?.string;
    return s == null || s.isEmpty ? null : s;
  }

  /// When the card compares, an attribute absent from [compareTo] counts as a
  /// mismatch, like ordinary string rows.
  static AttributeComparison _compare(
    schemaless.Attribute attribute,
    List<schemaless.Attribute>? compareTo,
  ) {
    if (compareTo == null) return AttributeComparison.none;
    final other = compareTo.firstWhereOrNull(
      (c) => listEquals(c.claimPath, attribute.claimPath),
    );
    if (other == null) return AttributeComparison.mismatch;
    return _comparable(other.value) == _comparable(attribute.value)
        ? AttributeComparison.match
        : AttributeComparison.mismatch;
  }

  static Object? _comparable(schemaless.AttributeValue? v) =>
      v?.string ?? v?.boolValue ?? v?.intValue;
}

enum _Field { held, issued, expires }

class _CategoryAttributes {
  schemaless.Attribute? held;
  schemaless.Attribute? issued;
  schemaless.Attribute? expires;

  bool get isEmpty => [
    held,
    issued,
    expires,
  ].every((a) => !(a?.value?.hasConcreteValue ?? false));
}

enum AttributeComparison { none, match, mismatch }

class CompareValue<T> {
  final T value;
  final AttributeComparison comparison;
  const CompareValue(this.value, this.comparison);
}

/// One held category. Fields are null when that attribute was not given,
/// e.g. a disclosure of only the expiry date.
class CategoryRow {
  final String code;
  final CompareValue<bool?>? held;
  final CompareValue<String>? issued;
  final CompareValue<String>? expires;

  const CategoryRow({required this.code, this.held, this.issued, this.expires});
}

class DrivingLicenceCategoriesView {
  final List<CategoryRow> held;
  final List<CompareValue<String>> notHeld;

  /// Every claimed attribute was empty: the licence chip held no category data.
  final bool noInformation;

  const DrivingLicenceCategoriesView({
    required this.held,
    required this.notHeld,
  }) : noInformation = false;

  const DrivingLicenceCategoriesView.noInformation()
    : held = const [],
      notHeld = const [],
      noInformation = true;
}

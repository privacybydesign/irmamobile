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
      placement: const AttributeGroupPlacement.end(),
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

    final rows = <CategoryRow>[];
    for (final code in codes) {
      final c = byCode[code];
      if (c == null) continue;
      // An empty held flag is read as not held.
      final heldFlag = _bool(c.held?.value) ?? (c.held == null ? null : false);
      final issued = _string(c.issued?.value);
      final expires = _string(c.expires?.value);
      if (c.held == null && issued == null && expires == null) continue;

      rows.add(
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
    }
    return DrivingLicenceCategoriesView(
      rows: rows,
      complete: codes.every((code) {
        final c = byCode[code];
        return c != null &&
            c.held != null &&
            c.issued != null &&
            c.expires != null;
      }),
      showsIssued: byCode.values.any((c) => c.issued != null),
      showsExpires: byCode.values.any((c) => c.expires != null),
    );
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

/// One category. Fields are null when that attribute was not given, e.g. a
/// disclosure of only the expiry date.
class CategoryRow {
  final String code;
  final CompareValue<bool?>? held;
  final CompareValue<String>? issued;
  final CompareValue<String>? expires;

  const CategoryRow({required this.code, this.held, this.issued, this.expires});

  /// The licence says this category is not held: a "no" (or empty) held flag
  /// and no dates. Not the same as a row whose dates were simply not given.
  bool get notHeld =>
      held != null && held!.value != true && issued == null && expires == null;
}

class DrivingLicenceCategoriesView {
  /// In licence-card order.
  final List<CategoryRow> rows;

  /// Every claimed attribute was empty: the licence chip held no category data.
  final bool noInformation;

  /// Whether any issue date / expiry date attribute was given (even empty), so
  /// the table shows that column. A disclosure of just the held flags shows
  /// neither.
  final bool showsIssued;
  final bool showsExpires;

  /// Every category attribute was given, as on the credential detail screen.
  /// False for a subset, i.e. a disclosure, where every shared category must
  /// be visible.
  final bool complete;

  const DrivingLicenceCategoriesView({
    required this.rows,
    required this.complete,
    required this.showsIssued,
    required this.showsExpires,
  }) : noInformation = false;

  const DrivingLicenceCategoriesView.noInformation()
    : rows = const [],
      complete = true,
      showsIssued = false,
      showsExpires = false,
      noInformation = true;
}

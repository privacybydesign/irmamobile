import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../theme/theme.dart";

/// How a value compares to the card's `compareTo` list: no comparison, or a
/// match (green) / mismatch (red), as ordinary attribute rows colour it.
enum AttributeComparison { none, match, mismatch }

/// Compares [attribute] with its counterpart (same claim path) in
/// [compareTo]. When the card compares, an attribute absent from [compareTo]
/// is a mismatch, like ordinary string rows.
AttributeComparison compareAttribute(
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

Object? _comparable(schemaless.AttributeValue? v) =>
    v?.string ?? v?.boolValue ?? v?.intValue;

/// Combines the comparisons of the attributes behind one displayed value:
/// any mismatch wins, then any match.
AttributeComparison combineComparisons(Iterable<AttributeComparison> all) =>
    all.contains(AttributeComparison.mismatch)
    ? AttributeComparison.mismatch
    : all.contains(AttributeComparison.match)
    ? AttributeComparison.match
    : AttributeComparison.none;

Color comparisonColor(IrmaThemeData theme, AttributeComparison comparison) =>
    switch (comparison) {
      AttributeComparison.none => theme.dark,
      AttributeComparison.match => theme.success,
      AttributeComparison.mismatch => theme.error,
    };

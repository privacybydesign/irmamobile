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
  return sameAttributeValue(other.value, attribute.value)
      ? AttributeComparison.match
      : AttributeComparison.mismatch;
}

/// Whether two values say the same. IRMA sends requested values as strings,
/// so a "yes" / "no" string equals the boolean true / false, and a number
/// equals its digits.
bool sameAttributeValue(
  schemaless.AttributeValue? a,
  schemaless.AttributeValue? b,
) => comparableAttributeValue(a) == comparableAttributeValue(b);

/// [v] as a bool, a string or null, for [sameAttributeValue].
Object? comparableAttributeValue(schemaless.AttributeValue? v) {
  if (v == null) return null;
  if (v.boolValue != null) return v.boolValue;
  if (v.intValue != null) return "${v.intValue}";
  final s = v.string;
  return switch (s?.trim().toLowerCase()) {
    "yes" || "true" => true,
    "no" || "false" => false,
    _ => s,
  };
}

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

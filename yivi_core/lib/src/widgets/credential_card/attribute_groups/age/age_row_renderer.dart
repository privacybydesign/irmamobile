import "../../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../attribute_group.dart";
import "age_row.dart";

/// Folds a credential's `overNN` attributes into one age row ("Ouder dan 21,
/// niet ouder dan 65") that expands into one chip per age. Applies to every
/// credential type.
///
/// When the card compares against another credential, every age keeps its own
/// row, so each can be coloured as a match or mismatch.
class AgeRowRenderer implements AttributeGroupRenderer {
  /// Where the row goes; by default the place of the first age attribute.
  final AttributeGroupPlacement placement;

  const AgeRowRenderer({
    this.placement = const AttributeGroupPlacement.inPlace(),
  });

  static final _ageClaim = RegExp(r"^over(\d+)$");

  @override
  AttributeGroup? claim(
    List<schemaless.Attribute> available, {
    List<schemaless.Attribute>? compareTo,
  }) {
    if (compareTo != null) return null;

    final ages = <AgeEntry>[];
    final claimed = <schemaless.Attribute>[];
    for (final attribute in available) {
      final entry = ageEntry(attribute);
      if (entry == null) continue;
      ages.add(entry);
      claimed.add(attribute);
    }
    if (ages.isEmpty) return null;

    ages.sort((a, b) => a.age.compareTo(b.age));
    return AttributeGroup(
      claimed: claimed,
      placement: placement,
      build: (_) => AgeRow(ages: ages),
    );
  }

  /// The age and its yes/no value, or null when [attribute] is not a
  /// top-level `overNN` attribute with a yes/no value.
  static AgeEntry? ageEntry(schemaless.Attribute attribute) {
    final path = attribute.claimPath;
    if (path.length != 1 || path.first is! String) return null;
    final age = _ageClaim.firstMatch(path.first as String)?.group(1);
    if (age == null) return null;

    final value = attribute.value;
    final over = switch (value?.type) {
      schemaless.AttributeType.boolean => value?.boolValue,
      schemaless.AttributeType.string => switch (value?.string?.toLowerCase()) {
        "yes" || "true" => true,
        "no" || "false" => false,
        _ => null,
      },
      _ => null,
    };
    if (over == null) return null;
    return AgeEntry(age: int.parse(age), over: over, attribute: attribute);
  }
}

/// One `overNN` attribute: whether the holder is older than [age].
class AgeEntry {
  final int age;
  final bool over;
  final schemaless.Attribute? attribute;

  const AgeEntry({required this.age, required this.over, this.attribute});
}

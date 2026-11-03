import "../../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../attribute_group.dart";
import "chip_check_pill.dart";

/// Shows `activeAuthentication` (whether the document's chip proved it is the
/// original when it was read) as a pill with an explanation, instead of a
/// yes / no field.
///
/// When comparing, or when the value is neither yes nor no, it claims nothing
/// and the attribute stays an ordinary field.
class ChipCheckRenderer implements AttributeGroupRenderer {
  const ChipCheckRenderer();

  static const attributeId = "activeAuthentication";

  @override
  AttributeGroup? claim(
    List<schemaless.Attribute> available, {
    List<schemaless.Attribute>? compareTo,
  }) {
    if (compareTo != null) return null;
    for (final attribute in available) {
      if (attribute.claimPath case [attributeId]) {
        final genuine = _yesNo(attribute.value);
        if (genuine == null) return null;
        return AttributeGroup(
          claimed: [attribute],
          placement: const AttributeGroupPlacement.inPlace(),
          build: (_) => ChipCheckPill(genuine: genuine),
        );
      }
    }
    return null;
  }

  static bool? _yesNo(schemaless.AttributeValue? value) =>
      value?.boolValue ??
      switch (value?.string?.trim().toLowerCase()) {
        "yes" || "true" => true,
        "no" || "false" => false,
        _ => null,
      };
}

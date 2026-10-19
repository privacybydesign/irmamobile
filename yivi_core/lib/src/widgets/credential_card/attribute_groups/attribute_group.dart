import "dart:convert";

import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;

/// Where an attribute group appears among a credential's ordinary attribute
/// rows. Image attributes stay below every group except an [EndPlacement] one.
sealed class AttributeGroupPlacement {
  const AttributeGroupPlacement();

  /// Before all ordinary rows.
  const factory AttributeGroupPlacement.top() = TopPlacement;

  /// After all ordinary rows, above images.
  const factory AttributeGroupPlacement.bottom() = BottomPlacement;

  /// After everything, images included.
  const factory AttributeGroupPlacement.end() = EndPlacement;

  /// Directly after the top-level attribute [attributeId]. When that
  /// attribute is not in the list (e.g. a disclosure subset), the group takes
  /// the position its first claimed attribute would have had.
  const factory AttributeGroupPlacement.after(String attributeId) =
      AfterPlacement;
}

class TopPlacement extends AttributeGroupPlacement {
  const TopPlacement();
}

class BottomPlacement extends AttributeGroupPlacement {
  const BottomPlacement();
}

class EndPlacement extends AttributeGroupPlacement {
  const EndPlacement();
}

class AfterPlacement extends AttributeGroupPlacement {
  final String attributeId;
  const AfterPlacement(this.attributeId);
}

/// A set of a credential's attributes drawn as one widget instead of as
/// ordinary rows.
class AttributeGroup {
  /// The attributes this group takes out of the ordinary list, identified by
  /// claim path. Must be a subset of what the renderer was offered.
  final List<schemaless.Attribute> claimed;
  final AttributeGroupPlacement placement;
  final WidgetBuilder build;

  const AttributeGroup({
    required this.claimed,
    required this.placement,
    required this.build,
  });
}

/// Draws some of a credential type's attributes as an [AttributeGroup].
///
/// A group must show exactly the attributes it claims and nothing more: on a
/// disclosure it is handed only what is being shared. The renderer owns the
/// comparison colouring for its attributes: [compareTo] is the card's raw
/// comparison list (null when the card compares nothing).
abstract interface class AttributeGroupRenderer {
  /// Pure: decides which of [available] to claim. Returns null to claim none.
  AttributeGroup? claim(
    List<schemaless.Attribute> available, {
    List<schemaless.Attribute>? compareTo,
  });
}

/// What a group needs to know about where it is drawn.
class AttributeGroupScope extends InheritedWidget {
  /// No attribute row is drawn above the group.
  final bool isFirst;

  /// The card is on a disclosure screen (or a disclosure in the activity
  /// log): the attributes are the ones being shared, not the whole
  /// credential.
  final bool isDisclosure;

  const AttributeGroupScope({
    super.key,
    required this.isFirst,
    required this.isDisclosure,
    required super.child,
  });

  static AttributeGroupScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AttributeGroupScope>();

  @override
  bool updateShouldNotify(AttributeGroupScope oldWidget) =>
      isFirst != oldWidget.isFirst || isDisclosure != oldWidget.isDisclosure;
}

/// Stable key for comparing claim paths.
String claimPathKey(List<dynamic> claimPath) => jsonEncode(claimPath);

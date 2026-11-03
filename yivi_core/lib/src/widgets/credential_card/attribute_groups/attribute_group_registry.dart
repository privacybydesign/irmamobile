import "age/age_row_renderer.dart";
import "attribute_group.dart";

/// Attribute group renderers per exact credential type id, for credential
/// types without a card layout (see `sections/card_layout.dart`, which covers
/// the identity credentials). In order: each renderer sees only the
/// attributes earlier ones left unclaimed, and groups that land in the same
/// slot appear in this order.
const Map<String, List<AttributeGroupRenderer>> attributeGroupRenderers = {};

/// Renderers that apply to every credential, after the ones for its type.
const List<AttributeGroupRenderer> anyCredentialRenderers = [AgeRowRenderer()];

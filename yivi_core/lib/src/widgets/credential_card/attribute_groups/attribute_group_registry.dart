import "attribute_group.dart";
import "driving_licence/driving_licence_categories_renderer.dart";

/// The attribute group renderers per exact credential type id, in order: each
/// renderer sees only the attributes earlier ones left unclaimed, and groups
/// that land in the same slot appear in this order.
const Map<String, List<AttributeGroupRenderer>> attributeGroupRenderers = {
  "pbdf.pbdf.drivinglicence": [DrivingLicenceCategoriesRenderer()],
  "pbdf-staging.pbdf.drivinglicence": [DrivingLicenceCategoriesRenderer()],
};

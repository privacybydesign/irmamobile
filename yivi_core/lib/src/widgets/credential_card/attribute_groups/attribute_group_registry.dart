import "attribute_group.dart";
import "driving_licence/driving_licence_categories_renderer.dart";
import "profile_header/profile_header_renderer.dart";

const _documentHeader = ProfileHeaderRenderer(DocumentProfileAdapter());
const _municipalityHeader = ProfileHeaderRenderer(MunicipalityProfileAdapter());
const _drivingLicence = [_documentHeader, DrivingLicenceCategoriesRenderer()];

/// The attribute group renderers per exact credential type id, in order: each
/// renderer sees only the attributes earlier ones left unclaimed, and groups
/// that land in the same slot appear in this order.
const Map<String, List<AttributeGroupRenderer>> attributeGroupRenderers = {
  "pbdf.pbdf.passport": [_documentHeader],
  "pbdf-staging.pbdf.passport": [_documentHeader],
  "pbdf.pbdf.idcard": [_documentHeader],
  "pbdf-staging.pbdf.idcard": [_documentHeader],
  "pbdf.pbdf.residencepermit": [_documentHeader],
  "pbdf-staging.pbdf.residencepermit": [_documentHeader],
  "pbdf.pbdf.drivinglicence": _drivingLicence,
  "pbdf-staging.pbdf.drivinglicence": _drivingLicence,
  "pbdf.gemeente.personalData": [_municipalityHeader],
  "irma-demo.gemeente.personalData": [_municipalityHeader],
};

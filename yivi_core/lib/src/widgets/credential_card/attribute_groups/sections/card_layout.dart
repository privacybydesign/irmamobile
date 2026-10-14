import "../age/age_row_renderer.dart";
import "../attribute_group.dart";
import "../chip_check/chip_check_renderer.dart";
import "../driving_licence/driving_licence_categories_renderer.dart";
import "../profile_header/profile_header_renderer.dart";

/// A titled part of an identity credential's card. It shows its groups
/// first, then its fields in a two-column grid, then its trailing groups;
/// it is not drawn when none of them has anything to show.
class CardSection {
  /// Translation key of the small uppercase title.
  final String titleKey;

  /// Group renderers, run in order on the attributes not yet claimed.
  final List<AttributeGroupRenderer> groups;

  /// Top-level attribute ids shown in the field grid, in this order.
  final List<String> fieldIds;

  /// Group renderers drawn below the field grid. They claim before the
  /// fields, so a field id can catch an attribute a renderer declines.
  final List<AttributeGroupRenderer> trailingGroups;

  /// Attribute ids the section takes and does not show, because another
  /// attribute on the card already says the same: id → that attribute's id.
  /// Only hidden when that attribute is given too, so a disclosure of just
  /// the hidden one still shows it.
  final Map<String, String> redundantIds;

  const CardSection({
    required this.titleKey,
    this.groups = const [],
    this.fieldIds = const [],
    this.trailingGroups = const [],
    this.redundantIds = const {},
  });
}

/// How an identity credential's card is divided into sections. Attributes no
/// section names end up in an untitled section at the end, so nothing is ever
/// hidden.
class CardLayout {
  final List<CardSection> sections;

  const CardLayout(this.sections);
}

const _prefix = "credential.sections";

const _documentHeader = ProfileHeaderRenderer(DocumentProfileAdapter());
const _municipalityHeader = ProfileHeaderRenderer(MunicipalityProfileAdapter());
const _ages = AgeRowRenderer();
const _chipCheck = ChipCheckRenderer();

const _documentCard = CardLayout([
  CardSection(
    titleKey: "$_prefix.person",
    groups: [_documentHeader, _ages],
    fieldIds: ["yearOfBirth", "isEuCitizen"],
  ),
  CardSection(
    titleKey: "$_prefix.document",
    fieldIds: [
      "documentNumber",
      "documentType",
      "dateOfIssue",
      "dateOfExpiry",
      "issuingAuthority",
      "country",
      "activeAuthentication",
    ],
    trailingGroups: [_chipCheck],
  ),
]);

const _drivingLicenceCard = CardLayout([
  CardSection(
    titleKey: "$_prefix.person",
    groups: [_documentHeader, _ages],
    // The year is in the date of birth the header shows.
    redundantIds: {"yearOfBirth": "dateOfBirth"},
  ),
  CardSection(
    titleKey: "$_prefix.driving_entitlement",
    groups: [DrivingLicenceCategoriesRenderer()],
  ),
  CardSection(
    titleKey: "$_prefix.document",
    fieldIds: [
      "documentNumber",
      "dateOfExpiry",
      "issuingAuthority",
      "issuingMemberState",
      "activeAuthentication",
    ],
    trailingGroups: [_chipCheck],
  ),
]);

const _municipalityCard = CardLayout([
  CardSection(
    titleKey: "$_prefix.person",
    groups: [_municipalityHeader, _ages],
    fieldIds: ["nationality"],
  ),
  CardSection(
    titleKey: "$_prefix.name",
    // The header shows the full or composed name; whatever it did not use
    // (initials, birth name, the name parts next to a full name) shows here.
    fieldIds: [
      "initials",
      "familyname",
      "fullname",
      "firstnames",
      "prefix",
      "surname",
    ],
  ),
  CardSection(
    titleKey: "$_prefix.registration",
    fieldIds: ["bsn", "digidlevel"],
  ),
]);

/// The card layout per exact credential type id.
const Map<String, CardLayout> cardLayouts = {
  "pbdf.pbdf.passport": _documentCard,
  "pbdf-staging.pbdf.passport": _documentCard,
  "pbdf.pbdf.idcard": _documentCard,
  "pbdf-staging.pbdf.idcard": _documentCard,
  "pbdf.pbdf.residencepermit": _documentCard,
  "pbdf-staging.pbdf.residencepermit": _documentCard,
  "pbdf.pbdf.drivinglicence": _drivingLicenceCard,
  "pbdf-staging.pbdf.drivinglicence": _drivingLicenceCard,
  "pbdf.gemeente.personalData": _municipalityCard,
  "irma-demo.gemeente.personalData": _municipalityCard,
};

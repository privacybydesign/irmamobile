import "../../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../age/age_row_renderer.dart";
import "../attribute_comparison.dart";
import "../attribute_group.dart";
import "../attribute_value_formatting.dart";
import "../requested_value.dart";
import "profile_header.dart";

/// Draws the person's photo, name and basic details as a header at the top of
/// an identity credential.
///
/// The header only appears when the name or the photo is among the given
/// attributes; otherwise it claims nothing and the details stay ordinary rows.
class ProfileHeaderRenderer implements AttributeGroupRenderer {
  final ProfileHeaderAdapter adapter;

  const ProfileHeaderRenderer(this.adapter);

  @override
  AttributeGroup? claim(
    List<schemaless.Attribute> available, {
    List<schemaless.Attribute>? compareTo,
  }) {
    final view = adapter.viewOf(available, compareTo: compareTo);
    if (view.name == null && view.photo == null) return null;
    return AttributeGroup(
      claimed: view.claimed,
      placement: const AttributeGroupPlacement.top(),
      build: (_) => ProfileHeader(view: view),
    );
  }
}

/// One value in the header, with the attribute(s) it was built from.
class ProfileField {
  /// The value as given; null when [translationKey] supplies the text.
  final String? text;

  /// A fixed text instead of a value (municipality "Dutch nationality: yes").
  final String? translationKey;

  final List<schemaless.Attribute> sources;
  final AttributeComparison comparison;

  ProfileField._(this.text, this.translationKey, this.sources, this.comparison);

  factory ProfileField.text(
    String text,
    List<schemaless.Attribute> sources,
    List<schemaless.Attribute>? compareTo,
  ) => ProfileField._(text, null, sources, _compare(sources, compareTo));

  factory ProfileField.translated(
    String translationKey,
    List<schemaless.Attribute> sources,
    List<schemaless.Attribute>? compareTo,
  ) => ProfileField._(
    null,
    translationKey,
    sources,
    _compare(sources, compareTo),
  );

  static AttributeComparison _compare(
    List<schemaless.Attribute> sources,
    List<schemaless.Attribute>? compareTo,
  ) => combineComparisons(sources.map((a) => compareAttribute(a, compareTo)));
}

/// What the header shows. Every field is null when its attributes are absent.
class ProfileHeaderView {
  final schemaless.Attribute? photo;
  final ProfileField? name;
  final ProfileField? dateOfBirth;
  final ProfileField? placeOfBirth;
  final ProfileField? nationality;
  final ProfileField? gender;

  /// The `overNN` attributes, shown as chips; empty when comparing.
  final AgeChips ages;

  /// `isEuCitizen` when it is yes (a no stays an ordinary field); null when
  /// comparing.
  final schemaless.Attribute? euCitizen;

  const ProfileHeaderView({
    this.photo,
    this.name,
    this.dateOfBirth,
    this.placeOfBirth,
    this.nationality,
    this.gender,
    this.ages = const AgeChips([], []),
    this.euCitizen,
    this.redundant = const [],
  });

  /// Attributes the header takes without showing, because what it shows
  /// already says the same (the full name next to the name parts).
  final List<schemaless.Attribute> redundant;

  /// Exactly the attributes the header shows, and the redundant ones.
  List<schemaless.Attribute> get claimed => [
    ...redundant,
    ?photo,
    for (final field in [name, dateOfBirth, placeOfBirth, nationality, gender])
      ...?field?.sources,
    ...ages.sources,
    ?euCitizen,
  ];
}

/// The holder's ages, sorted ascending, and the attributes they came from.
class AgeChips {
  final List<AgeEntry> entries;
  final List<schemaless.Attribute> sources;

  const AgeChips(this.entries, this.sources);
}

/// Maps one family of credential types onto the header's fields.
abstract interface class ProfileHeaderAdapter {
  ProfileHeaderView viewOf(
    List<schemaless.Attribute> available, {
    List<schemaless.Attribute>? compareTo,
  });
}

/// Passport, ID card, residence permit and driving licence.
class DocumentProfileAdapter implements ProfileHeaderAdapter {
  const DocumentProfileAdapter();

  @override
  ProfileHeaderView viewOf(
    List<schemaless.Attribute> available, {
    List<schemaless.Attribute>? compareTo,
  }) {
    final a = _Attributes(available, compareTo);
    return ProfileHeaderView(
      photo: a.photo("photo"),
      name: a.joined(["firstName", "lastName"], " "),
      dateOfBirth: a.single("dateOfBirth"),
      placeOfBirth: a.single("placeOfBirth"),
      nationality: a.single("nationality"),
      gender: a.single("gender"),
      ages: a.ages(),
      euCitizen: a.yes("isEuCitizen"),
    );
  }
}

/// The municipality's personal data (`gemeente.personalData`).
class MunicipalityProfileAdapter implements ProfileHeaderAdapter {
  const MunicipalityProfileAdapter();

  @override
  ProfileHeaderView viewOf(
    List<schemaless.Attribute> available, {
    List<schemaless.Attribute>? compareTo,
  }) {
    final a = _Attributes(available, compareTo);
    // First names and surname (Voornamen, Achternaam), the name as the
    // municipality uses it, partner name and prefix included; the full name
    // then says nothing more. Without both parts, the full name if given.
    final parts = a.joined(["firstnames", "surname"], " ");
    final fullname = a.single("fullname");
    final useParts = parts != null && parts.sources.length == 2;
    return ProfileHeaderView(
      name: useParts ? parts : fullname ?? parts,
      redundant: useParts && fullname != null ? fullname.sources : const [],
      dateOfBirth: a.single("dateofbirth"),
      placeOfBirth: a.joined(["cityofbirth", "countryofbirth"], ", "),
      nationality: a.dutchNationality("nationality"),
      gender: a.single("gender"),
      ages: a.ages(),
    );
  }
}

/// Lookup of top-level attributes by id, treating empty values as absent.
class _Attributes {
  final Map<String, schemaless.Attribute> _byId;
  final List<schemaless.Attribute>? compareTo;

  _Attributes(List<schemaless.Attribute> available, this.compareTo)
    : _byId = {
        for (final a in available)
          if (a.claimPath.length == 1 && a.claimPath.first is String)
            a.claimPath.first as String: a,
      };

  schemaless.Attribute? photo(String id) {
    final a = _byId[id];
    return a != null && decodeAttributeImage(a.value) != null ? a : null;
  }

  ProfileField? single(String id) => joined([id], "");

  /// The non-empty values of [ids] joined by [separator], or null when all
  /// are empty. Only the attributes that contribute are claimed.
  ProfileField? joined(List<String> ids, String separator) {
    final parts = <String>[];
    final sources = <schemaless.Attribute>[];
    for (final id in ids) {
      final a = _byId[id];
      final text = _text(a?.value);
      if (a == null || text == null) continue;
      parts.add(text);
      sources.add(a);
    }
    if (parts.isEmpty) return null;
    return ProfileField.text(parts.join(separator), sources, compareTo);
  }

  /// "Dutch nationality": only a yes is a nationality to show; a no stays an
  /// ordinary row.
  ProfileField? dutchNationality(String id) {
    final a = _byId[id];
    final v = a?.value;
    final yes =
        v?.boolValue ??
        switch (v?.string?.trim().toLowerCase()) {
          "yes" || "ja" || "true" => true,
          _ => false,
        };
    if (a == null || !yes) return null;
    return ProfileField.translated("credential.profile_header.dutch", [
      a,
    ], compareTo);
  }

  /// The `overNN` attributes. When comparing, every age keeps its own row so
  /// it can be coloured, so there are none; when the verifier asked for an
  /// age, the age row shows it with its requested-value chip.
  AgeChips ages() {
    if (compareTo != null) return const AgeChips([], []);
    if (_byId.values.any(
      (a) => hasRequestedValue(a) && AgeRowRenderer.ageEntry(a) != null,
    )) {
      return const AgeChips([], []);
    }
    final entries = <AgeEntry>[];
    final sources = <schemaless.Attribute>[];
    for (final a in _byId.values) {
      final entry = AgeRowRenderer.ageEntry(a);
      if (entry == null) continue;
      entries.add(entry);
      sources.add(a);
    }
    entries.sort((x, y) => x.age.compareTo(y.age));
    return AgeChips(entries, sources);
  }

  /// The attribute [id] when its value is yes, and not comparing.
  schemaless.Attribute? yes(String id) {
    final a = _byId[id];
    final v = a?.value;
    final yes =
        v?.boolValue ??
        switch (v?.string?.trim().toLowerCase()) {
          "yes" || "ja" || "true" => true,
          _ => false,
        };
    return compareTo == null && yes && !hasRequestedValue(a!) ? a : null;
  }

  static String? _text(schemaless.AttributeValue? v) {
    final text = (v?.string ?? v?.intValue?.toString())?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}

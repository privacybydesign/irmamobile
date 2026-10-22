import "package:flutter_i18n/flutter_i18n.dart";
// ignore: implementation_imports
import "package:intl_phone_number_input/src/models/country_model.dart";
import "package:material_ui/material_ui.dart";

import "../../../../providers/credentials_search.dart";
import "../../../../theme/yivi_corners.dart";
import "../../../../theme/yivi_palette.dart";
import "../../../../util/adaptive_layout.dart";
import "../../../../widgets/glass/glass_group.dart";
import "../../../../widgets/glass/glass_search_field.dart";
import "../../../../widgets/glass/glass_sheet.dart";

/// The name of [country] in [languageCode], else its English name.
String countryName(Country country, String? languageCode) =>
    country.nameTranslations?[languageCode] ?? country.name ?? "";

/// The flag of [country], from intl_phone_number_input's assets, with the
/// corners of a small card.
class CountryFlag extends StatelessWidget {
  final Country country;
  final double width;

  const CountryFlag({super.key, required this.country, this.width = 28});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final height = (width * 5 / 7).roundToDouble();
    return ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: palette.divider,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(width * 0.16),
            side: BorderSide(color: palette.text.withValues(alpha: 0.08)),
          ),
        ),
        child: Image.asset(
          country.flagUri,
          package: "intl_phone_number_input",
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// The country of a phone number, picked in a sheet like every other one in
/// the app: a search field, the countries most people pick, then all of them
/// by name, each with its flag and dialling code. The one in use has a
/// check. Returns the picked country, or null when the sheet is closed.
Future<Country?> showCountryPickerSheet({
  required BuildContext context,
  required List<Country> countries,
  required Country selected,
  required List<String> common,
}) => showGlassSheet<Country>(
  context: context,
  builder: (_) =>
      _CountryPicker(countries: countries, selected: selected, common: common),
);

class _CountryPicker extends StatefulWidget {
  final List<Country> countries;
  final Country selected;
  final List<String> common;

  const _CountryPicker({
    required this.countries,
    required this.selected,
    required this.common,
  });

  @override
  State<_CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<_CountryPicker> {
  String _query = "";

  String _t(String key) =>
      FlutterI18n.translate(context, "sms_issuance.enter_phone.$key");

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final language = FlutterI18n.currentLocale(context)?.languageCode;
    String name(Country c) => countryName(c, language);

    final byName = [...widget.countries]
      ..sort(
        (a, b) =>
            normaliseForSearch(name(a)).compareTo(normaliseForSearch(name(b))),
      );
    final common = [
      for (final code in widget.common)
        ...widget.countries.where((c) => c.alpha2Code == code),
    ];

    final query = normaliseForSearch(_query);
    final digits = _query.replaceAll(RegExp(r"[^\d]"), "");
    bool matches(Country c) =>
        normaliseForSearch(name(c)).contains(query) ||
        normaliseForSearch(c.name ?? "").contains(query) ||
        (c.alpha2Code ?? "").toLowerCase() == query ||
        (digits.isNotEmpty &&
            (c.dialCode ?? "").replaceAll("+", "").startsWith(digits));
    final found = query.isEmpty ? const <Country>[] : byName.where(matches);

    final landscape = useSheetColumns(context);
    Widget row(Country c) => _CountryRow(
      country: c,
      name: name(c),
      selected: c.alpha2Code == widget.selected.alpha2Code,
      oneLine: landscape,
      onTap: () => Navigator.of(context).pop(c),
    );
    // A phone held sideways: three countries side by side, each a card.
    Widget grid(String? header, List<Country> list) => SliverMainAxisGroup(
      slivers: [
        if (header != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
              child: Semantics(
                header: true,
                child: Text(header, style: palette.display(15)),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 12),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              mainAxisExtent:
                  52 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
            ),
            itemCount: list.length,
            itemBuilder: (context, i) => Material(
              color: palette.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(YiviCorners.card)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Center(child: row(list[i])),
            ),
          ),
        ),
      ],
    );

    Widget group(String? header, List<Country> list) => landscape
        ? grid(header, list)
        : SliverGlassGroup(
            header: header,
            dividerIndent: _CountryRow.dividerIndent,
            itemCount: list.length,
            itemBuilder: (context, i) => row(list[i]),
          );

    final search = GlassSearchField(
      fieldKey: const Key("phone_country_search"),
      hintKey: "sms_issuance.enter_phone.search_label",
      height: landscape ? 40 : 44,
      onChanged: (q) => setState(() => _query = q),
    );
    return GlassSheetPage(
      title: _t("country_title"),
      // Sideways the search field is in the bar, next to the title.
      titleWidget: landscape ? search : null,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      slivers: [
        if (!landscape) SliverToBoxAdapter(child: search),
        if (query.isEmpty) ...[
          if (landscape) const SliverToBoxAdapter(child: SizedBox(height: 8)),
          group(_t("country_common"), common),
          group(_t("country_all"), byName),
        ] else if (found.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Text(
                _t("country_none"),
                textAlign: TextAlign.center,
                style: palette.body(16).copyWith(color: palette.secondaryText),
              ),
            ),
          )
        else ...[
          // As far below the search field as a list under a header.
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          group(null, found.toList()),
        ],
      ],
    );
  }
}

/// A country in the picker: its flag, its name and its dialling code, and a
/// check on the one in use.
class _CountryRow extends StatelessWidget {
  final Country country;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  /// The name on one line (the grid of a phone held sideways).
  final bool oneLine;

  static const double dividerIndent = 14 + 28 + 12;

  const _CountryRow({
    required this.country,
    required this.name,
    required this.selected,
    required this.onTap,
    this.oneLine = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: "$name, ${country.dialCode}",
      onTap: onTap,
      child: InkWell(
        key: Key("phone_country_${country.alpha2Code}"),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Row(
              spacing: 12,
              children: [
                CountryFlag(country: country),
                Expanded(
                  child: Text(
                    name,
                    maxLines: oneLine ? 1 : null,
                    overflow: oneLine ? TextOverflow.ellipsis : null,
                    style: palette.body(16).copyWith(color: palette.text),
                  ),
                ),
                Text(
                  country.dialCode ?? "",
                  style: palette
                      .body(15)
                      .copyWith(color: palette.secondaryText),
                ),
                SizedBox(
                  width: 20,
                  child: selected
                      ? Icon(Icons.check_rounded, size: 20, color: palette.link)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../../../package_name.dart";

import "../../../../theme/theme.dart";
import "../../../link.dart";
import "../attribute_value_formatting.dart";
import "driving_licence_categories_renderer.dart";

/// Driving licence categories laid out like the back of the licence card: a
/// Category / Issued / Expires table with one row per category, where a
/// category that is not held shows "-" for its dates.
///
/// Collapsed by default to the categories held, with a "show all" toggle for
/// the rest. A subset of the categories (a disclosure) starts expanded, so
/// everything being shared is visible without a tap. When nothing or
/// everything given is held there is nothing to hide, so the table shows
/// every row and no toggle.
class DrivingLicenceCategoriesTable extends StatefulWidget {
  final DrivingLicenceCategoriesView view;

  const DrivingLicenceCategoriesTable({required this.view})
    : super(key: const Key("attribute_group_driving_licence_categories"));

  @override
  State<DrivingLicenceCategoriesTable> createState() =>
      _DrivingLicenceCategoriesTableState();
}

class _DrivingLicenceCategoriesTableState
    extends State<DrivingLicenceCategoriesTable> {
  static const _prefix = "credential.driving_licence_categories";

  late var _expanded = !widget.view.complete;

  DrivingLicenceCategoriesView get view => widget.view;

  bool get _collapsible =>
      view.rows.any((r) => r.notHeld) && view.rows.any((r) => !r.notHeld);

  List<CategoryRow> get _visibleRows => _expanded || !_collapsible
      ? view.rows
      : view.rows.where((r) => !r.notHeld).toList();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    String t(String key) => FlutterI18n.translate(context, "$_prefix.$key");

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        Text(t("title"), style: attributeLabelStyle(theme)),
        if (view.noInformation)
          Text(
            t("no_information"),
            style: attributeLabelStyle(
              theme,
            ).copyWith(color: theme.neutral, fontStyle: FontStyle.italic),
          ),
        if (view.rows.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: theme.tinySpacing),
            child: _table(theme, t),
          ),
        if (_collapsible)
          Padding(
            padding: EdgeInsets.only(top: theme.smallSpacing),
            child: KeyedSubtree(
              key: const Key("driving_licence_categories_toggle"),
              child: Link(
                label: "$_prefix.${_expanded ? "show_less" : "show_all"}",
                // Regular weight: a quiet toggle, not a call to action.
                style: const TextStyle(fontWeight: FontWeight.w400),
                onTap: () => setState(() => _expanded = !_expanded),
              ),
            ),
          ),
      ],
    );
  }

  Widget _table(IrmaThemeData theme, String Function(String) t) {
    final cellPadding = EdgeInsets.symmetric(vertical: theme.tinySpacing);
    final dateStyle = attributeValueStyle(
      theme,
      theme.dark,
    ).copyWith(fontSize: 14);

    Widget header(String text) => Padding(
      padding: cellPadding,
      child: Text(text.toUpperCase(), style: attributeEyebrowStyle(theme)),
    );

    Widget date(CategoryRow row, CompareValue<String>? value) => Padding(
      padding: cellPadding,
      child: Text(
        row.notHeld ? "-" : value?.value ?? "",
        style: dateStyle.copyWith(
          color: value == null
              ? null
              : comparisonColor(theme, value.comparison),
        ),
      ),
    );

    final divider = BoxDecoration(
      border: Border(top: BorderSide(color: theme.neutralExtraLight)),
    );

    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            header(t("category")),
            header(t("issued")),
            header(t("expires")),
          ],
        ),
        for (final row in _visibleRows)
          TableRow(
            key: ValueKey("driving_licence_category_${row.code}"),
            decoration: divider,
            children: [
              Padding(
                padding: cellPadding.copyWith(right: theme.mediumSpacing),
                child: _CategoryCell(row: row),
              ),
              date(row, row.issued),
              date(row, row.expires),
            ],
          ),
      ],
    );
  }
}

/// Vehicle icon(s) followed by the category code.
class _CategoryCell extends StatelessWidget {
  final CategoryRow row;

  const _CategoryCell({required this.row});

  // Fits a vehicle plus trailer, so codes line up across rows. Pictograms are
  // right-aligned in it, so they sit against the category code.
  static const _iconSlotWidth = 44.0;
  static const _iconSize = 20.0;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final (vehicle, trailer) = vehicleIcons(row.code);

    return Row(
      mainAxisSize: .min,
      children: [
        SizedBox(
          width: _iconSlotWidth,
          child: Row(
            mainAxisAlignment: .end,
            children: [
              _icon(vehicle, theme),
              if (trailer) _icon("trailer", theme),
            ],
          ),
        ),
        SizedBox(width: theme.smallSpacing),
        Text(
          row.code,
          style: attributeValueStyle(
            theme,
            comparisonColor(
              theme,
              row.held?.comparison ?? AttributeComparison.none,
            ),
          ),
        ),
      ],
    );
  }
}

Widget _icon(String asset, IrmaThemeData theme) => SvgPicture.asset(
  yiviAsset("vehicles/$asset.svg"),
  width: _CategoryCell._iconSize,
  height: _CategoryCell._iconSize,
  colorFilter: ColorFilter.mode(theme.neutralDark, BlendMode.srcIn),
);

/// The vehicle pictogram for a category, and whether a trailer follows it.
/// Filled side profiles facing left, distinguished per row like the
/// pictograms on the Dutch licence card (EC specimen NL8): CE is one
/// articulated lorry, the other E categories add a separate trailer.
(String, bool) vehicleIcons(String code) => switch (code) {
  "AM" => ("moped", false),
  "A1" => ("motorcycle_light", false),
  "A2" => ("motorcycle_medium", false),
  "A" => ("motorcycle", false),
  "B1" => ("van", false),
  "B" => ("car", false),
  "BE" => ("car", true),
  "C1" => ("truck_small", false),
  "C1E" => ("truck_small", true),
  "C" => ("truck", false),
  "CE" => ("articulated", false),
  "D1" => ("minibus", false),
  "D1E" => ("minibus", true),
  "D" => ("bus", false),
  "DE" => ("bus", true),
  "T" => ("tractor", false),
  _ => ("car", false),
};

Color comparisonColor(IrmaThemeData theme, AttributeComparison comparison) =>
    switch (comparison) {
      AttributeComparison.none => theme.dark,
      AttributeComparison.match => theme.success,
      AttributeComparison.mismatch => theme.error,
    };

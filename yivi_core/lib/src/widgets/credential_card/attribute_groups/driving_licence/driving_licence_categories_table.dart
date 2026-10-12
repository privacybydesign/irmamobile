import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../../theme/theme.dart";
import "../attribute_value_formatting.dart";
import "driving_licence_categories_renderer.dart";

/// Plain presentation of driving licence categories: one row per held
/// category, one line listing the categories not held.
class DrivingLicenceCategoriesTable extends StatelessWidget {
  final DrivingLicenceCategoriesView view;

  const DrivingLicenceCategoriesTable({required this.view})
    : super(key: const Key("attribute_group_driving_licence_categories"));

  static const _prefix = "credential.driving_licence_categories";

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
        for (final row in view.held)
          Padding(
            padding: EdgeInsets.only(top: theme.tinySpacing),
            child: _CategoryRowView(row: row, t: t),
          ),
        if (view.notHeld.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: theme.tinySpacing),
            child: Text.rich(
              TextSpan(
                style: attributeLabelStyle(theme),
                children: [
                  TextSpan(text: "${t("not_held")}: "),
                  for (final (i, code) in view.notHeld.indexed) ...[
                    if (i > 0) const TextSpan(text: ", "),
                    TextSpan(
                      text: code.value,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: comparisonColor(theme, code.comparison),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryRowView extends StatelessWidget {
  final CategoryRow row;
  final String Function(String) t;

  const _CategoryRowView({required this.row, required this.t});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final codeColor = comparisonColor(
      theme,
      row.held?.comparison ?? AttributeComparison.none,
    );

    Widget date(String label, CompareValue<String> value) => Text.rich(
      TextSpan(
        style: attributeLabelStyle(theme),
        children: [
          TextSpan(text: "$label "),
          TextSpan(
            text: value.value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: comparisonColor(theme, value.comparison),
            ),
          ),
        ],
      ),
    );

    return Row(
      crossAxisAlignment: .start,
      children: [
        SizedBox(
          width: 48,
          child: Text(row.code, style: attributeValueStyle(theme, codeColor)),
        ),
        Expanded(
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              if (row.issued != null) date(t("issued"), row.issued!),
              if (row.expires != null) date(t("expires"), row.expires!),
            ],
          ),
        ),
      ],
    );
  }
}

Color comparisonColor(IrmaThemeData theme, AttributeComparison comparison) =>
    switch (comparison) {
      AttributeComparison.none => theme.dark,
      AttributeComparison.match => theme.success,
      AttributeComparison.mismatch => theme.error,
    };

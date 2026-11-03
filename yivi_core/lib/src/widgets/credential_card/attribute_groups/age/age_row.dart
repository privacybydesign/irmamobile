import "package:collection/collection.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../../theme/theme.dart";
import "../../../link.dart";
import "../../../translated_text.dart";
import "../attribute_chip.dart";
import "../attribute_value_formatting.dart";
import "../requested_value.dart";
import "age_row_renderer.dart";

/// The age row: the highest age that is true and the lowest that is false, or,
/// once expanded, one chip per age.
class AgeRow extends StatefulWidget {
  /// Sorted by age, ascending.
  final List<AgeEntry> ages;

  const AgeRow({required this.ages})
    : super(key: const Key("attribute_group_age_row"));

  @override
  State<AgeRow> createState() => _AgeRowState();
}

class _AgeRowState extends State<AgeRow> {
  var _expanded = false;

  String _summary(BuildContext context) {
    final ages = widget.ages;
    final over = ages.where((a) => a.over).map((a) => a.age).lastOrNull;
    final notOver = ages.where((a) => !a.over).map((a) => a.age).firstOrNull;

    final (key, params) = switch ((over, notOver)) {
      (final over?, final notOver?) => (
        "credential.age.over_and_not_over",
        {"over": "$over", "notOver": "$notOver"},
      ),
      (final over?, null) => ("credential.age.over", {"age": "$over"}),
      (null, final notOver?) => (
        "credential.age.not_over",
        {"age": "$notOver"},
      ),
      (null, null) => ("", <String, String>{}),
    };
    return FlutterI18n.translate(context, key, translationParams: params);
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    // Nothing to expand into when there is only one age.
    final canExpand = widget.ages.length > 1;

    return WithRequestedValueChip(
      attributes: [for (final a in widget.ages) ?a.attribute],
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          TranslatedText(
            "credential.age.label",
            style: attributeLabelStyle(theme),
          ),
          if (_expanded)
            Padding(
              padding: EdgeInsets.only(top: theme.tinySpacing),
              child: Wrap(
                spacing: theme.smallSpacing,
                runSpacing: theme.smallSpacing,
                children: [for (final entry in widget.ages) AgeChip(entry)],
              ),
            )
          else
            Text(
              _summary(context),
              style: attributeValueStyle(theme, theme.dark),
            ),
          if (canExpand)
            Padding(
              padding: EdgeInsets.only(top: theme.tinySpacing),
              child: Link(
                label: _expanded
                    ? "credential.age.hide_all"
                    : "credential.age.show_all",
                // Regular weight: a quiet toggle, not a call to action.
                style: const TextStyle(fontWeight: FontWeight.w400),
                onTap: () => setState(() => _expanded = !_expanded),
              ),
            ),
        ],
      ),
    );
  }
}

/// One age as a chip: green when the holder is older, grey when not.
class AgeChip extends StatelessWidget {
  final AgeEntry entry;

  const AgeChip(this.entry, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    // The wording says which side of the age it is, so the colour is only a
    // second cue.
    return AttributeChip(
      text: FlutterI18n.translate(
        context,
        entry.over ? "credential.age.over" : "credential.age.not_over",
        translationParams: {"age": "${entry.age}"},
      ),
      background: entry.over ? theme.successSurface : theme.neutralExtraLight,
    );
  }
}

/// The ages worth showing on their own: the highest the holder is older than
/// and the lowest they are not, which together imply all the others.
/// [ages] must be sorted ascending.
List<AgeEntry> summaryAges(List<AgeEntry> ages) => [
  ?ages.where((a) => a.over).lastOrNull,
  ?ages.where((a) => !a.over).firstOrNull,
];

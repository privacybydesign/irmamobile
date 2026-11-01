import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/corner_badge.dart";
import "../../../widgets/press_scale.dart";
import "../activity_entry.dart";

/// The height of the rows of tags and suggestions under the activity
/// search field.
const double activityChipHeight = 36;

/// The height of a tag or a suggestion in those rows.
const double activityTagHeight = 32;

/// A filter that is on, under the activity search field: its name and a
/// cross that takes it off. Only filters that are on show a tag.
class ActivityFacetChip extends StatelessWidget {
  final String label;

  /// Before the label: the card's art, the party's logo, the kinds' badges,
  /// a calendar for a period.
  final Widget? leading;
  final VoidCallback onRemove;

  const ActivityFacetChip({
    super.key,
    required this.label,
    required this.onRemove,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final leading = this.leading;
    final fill = palette.link;
    final ink = palette.onLink;
    return Semantics(
      button: true,
      label: FlutterI18n.translate(
        context,
        "activity.query.remove_filter",
        translationParams: {"filter": label},
      ),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onRemove,
        child: PressScale(
          scale: PressScale.glass,
          child: Container(
            height: activityTagHeight,
            padding: EdgeInsets.fromLTRB(leading == null ? 12 : 4, 0, 10, 0),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: YiviCorners.chipRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                ?leading,
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: palette.display(13).copyWith(color: ink),
                  ),
                ),
                Icon(Icons.close_rounded, size: 16, color: ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A suggestion in the row under the activity search field and its tags:
/// what it is (a kind's dot, a card's art, a party's logo), its name and a
/// plus. Picking it adds it to the question as a tag.
class ActivitySuggestionChip extends StatelessWidget {
  final String label;
  final Widget? leading;
  final VoidCallback onTap;

  const ActivitySuggestionChip({
    super.key,
    required this.label,
    required this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final leading = this.leading;
    return Semantics(
      button: true,
      label: FlutterI18n.translate(
        context,
        "activity.query.add_filter",
        translationParams: {"filter": label},
      ),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: PressScale(
          scale: PressScale.glass,
          child: Container(
            height: activityTagHeight,
            padding: EdgeInsets.fromLTRB(leading == null ? 12 : 6, 0, 10, 0),
            decoration: ShapeDecoration(
              color: palette.surface,
              shape: RoundedRectangleBorder(
                borderRadius: YiviCorners.chipRadius,
                side: BorderSide(color: palette.divider),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                ?leading,
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: palette
                        .display(13, weight: FontWeight.w500)
                        .copyWith(color: palette.text),
                  ),
                ),
                Icon(Icons.add_rounded, size: 16, color: palette.secondaryText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A tag to pick in the filter sheet. Picked, it is filled; [included] when
/// a whole group around it is picked (lightly filled); [faded] when picking
/// it would leave nothing with the rest of the filter, and then it does not
/// react.
class ActivityToggleTag extends StatelessWidget {
  final String label;

  /// A kind's coloured badge before the label.
  final ActivityKind? kind;
  final bool selected;
  final bool included;
  final bool faded;
  final VoidCallback onTap;

  const ActivityToggleTag({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.kind,
    this.included = false,
    this.faded = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final kind = this.kind;
    final fill = selected
        ? palette.heading
        : included
        ? palette.tint
        : null;
    return Semantics(
      button: true,
      selected: selected || included,
      enabled: !faded,
      child: Opacity(
        opacity: faded ? 0.38 : 1,
        child: GestureDetector(
          onTap: faded ? null : onTap,
          child: PressScale(
            scale: faded ? 1 : PressScale.glass,
            // Flat, on the sheet: a thin edge, no shadow.
            child: Container(
              decoration: ShapeDecoration(
                color: fill ?? palette.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: YiviCorners.chipRadius,
                  side: fill == null
                      ? BorderSide(color: palette.divider)
                      : BorderSide.none,
                ),
              ),
              padding: EdgeInsets.fromLTRB(kind == null ? 14 : 9, 0, 14, 0),
              child: SizedBox(
                height: activityChipHeight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    if (kind != null)
                      ExcludeSemantics(
                        child: CornerBadge(
                          icon: kind.icon,
                          fill: kind.badge,
                          size: 18,
                          iconSize: 11,
                        ),
                      ),
                    Text(
                      label,
                      style: palette
                          .display(13)
                          .copyWith(
                            color: selected ? palette.surface : palette.text,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

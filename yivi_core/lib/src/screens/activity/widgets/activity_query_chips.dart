import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../widgets/corner_badge.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../activity_entry.dart";

/// The height of the chips and tags of the activity query.
const double activityChipHeight = 36;

/// A filter that is on, under the activity search field: its name and a
/// cross that takes it off. Only filters that are on show a chip.
class ActivityFacetChip extends StatelessWidget {
  final String label;

  /// Before the label: the card's art for a card filter.
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
            height: activityChipHeight,
            padding: EdgeInsets.fromLTRB(leading == null ? 12 : 6, 0, 5, 0),
            decoration: ShapeDecoration(
              color: palette.link,
              shape: const StadiumBorder(),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                ?leading,
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: palette.display(13).copyWith(color: Colors.white),
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
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
            child: GlassSurface(
              fill: fill,
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

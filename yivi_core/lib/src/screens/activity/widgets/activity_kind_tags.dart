import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../widgets/corner_badge.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../activity_entry.dart";

/// The row of tags under the activity search field: All, then one per
/// [ActivityKind]. The picked one is filled.
class ActivityKindTags extends StatelessWidget {
  /// The picked kind; null is All.
  final ActivityKind? selected;
  final ValueChanged<ActivityKind?> onSelected;

  /// Clips the row at the sides of the list column it sits in; else the
  /// tags run on to the screen's edge.
  final bool clip;

  const ActivityKindTags({
    super.key,
    required this.selected,
    required this.onSelected,
    this.clip = false,
  });

  static const double height = 36;

  static const _order = [
    ActivityKind.received,
    ActivityKind.shared,
    ActivityKind.signed,
    ActivityKind.deleted,
  ];

  @override
  Widget build(BuildContext context) {
    final row = Semantics(
      label: FlutterI18n.translate(context, "activity.filter_label"),
      container: true,
      child: SizedBox(
        height: height + 8,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              _Tag(
                key: const Key("activity_tag_all"),
                label: FlutterI18n.translate(context, "activity.kind.all"),
                selected: selected == null,
                onTap: () => onSelected(null),
              ),
              for (final kind in _order)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _Tag(
                    key: Key("activity_tag_${kind.name}"),
                    label: FlutterI18n.translate(context, kind.labelKey),
                    kind: kind,
                    selected: selected == kind,
                    onTap: () => onSelected(kind),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (!clip) return row;
    // Only at the sides, 16 out to the edge of the list column: a clip at
    // the row's own edges cut the tags' shadows off in a visible line.
    return ClipRect(clipper: const _SidesClipper(16), child: row);
  }
}

class _SidesClipper extends CustomClipper<Rect> {
  final double outset;

  const _SidesClipper(this.outset);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-outset, -64, size.width + outset, size.height + 64);

  @override
  bool shouldReclip(_SidesClipper old) => old.outset != outset;
}

class _Tag extends StatelessWidget {
  final String label;
  final ActivityKind? kind;
  final bool selected;
  final VoidCallback onTap;

  const _Tag({
    super.key,
    required this.label,
    this.kind,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final kind = this.kind;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: PressScale(
          scale: PressScale.glass,
          child: GlassSurface(
            fill: selected ? palette.heading : null,
            padding: EdgeInsets.fromLTRB(kind == null ? 14 : 9, 0, 14, 0),
            child: SizedBox(
              height: ActivityKindTags.height,
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
    );
  }
}

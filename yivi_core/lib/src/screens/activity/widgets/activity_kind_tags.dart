import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../activity_entry.dart";

/// The row of tags under the activity search field: All, then one per
/// [ActivityKind]. The picked one is filled.
class ActivityKindTags extends StatelessWidget {
  /// The picked kind; null is All.
  final ActivityKind? selected;
  final ValueChanged<ActivityKind?> onSelected;

  /// Clips the row at its edges, where it sits in a list column; else the
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
    return Semantics(
      label: FlutterI18n.translate(context, "activity.filter_label"),
      container: true,
      child: SizedBox(
        height: height + 8,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: clip ? Clip.hardEdge : Clip.none,
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
  }
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
          scale: 1.06,
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
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: kind.badge,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(kind.icon, size: 11, color: Colors.white),
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

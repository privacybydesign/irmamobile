import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";
import "../theme/yivi_space.dart";

/// What stands at the end of a [ListRow].
enum RowTrailing { chevron, check, none }

/// A row of a list or group: an optional [leading] picture, the [title]
/// with a [subtitle] under it, an optional grey [value], and a chevron or a
/// check at the end. It lights up grey under the finger.
class ListRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;

  /// Grey text before the trailing, e.g. the current language.
  final String? value;
  final RowTrailing trailing;

  /// Wins over [trailing].
  final Widget? trailingWidget;
  final VoidCallback? onTap;

  /// What a detail pane shows: the row is tinted and its chevron blue.
  final bool selected;

  /// A destructive action: a red title, no chevron.
  final bool danger;

  /// When false the row is greyed out and ignores taps.
  final bool enabled;

  /// A link for screen readers (opens a page) rather than a button.
  final bool link;

  /// Extra space at the start, for a row that belongs to the one above.
  final double indent;
  final int subtitleMaxLines;

  const ListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.value,
    this.trailing = RowTrailing.chevron,
    this.trailingWidget,
    this.onTap,
    this.selected = false,
    this.danger = false,
    this.enabled = true,
    this.link = false,
    this.indent = 0,
    this.subtitleMaxLines = 1,
  });

  /// The least height of a row.
  static const double height = 60;

  /// Its side, and the gap between its parts.
  static const double side = YiviSpace.x16;
  static const double gap = YiviSpace.x16;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final end =
        trailingWidget ??
        switch (danger ? RowTrailing.none : trailing) {
          RowTrailing.chevron => Icon(
            Icons.chevron_right,
            color: selected ? palette.link : palette.faint,
          ),
          RowTrailing.check => Icon(Icons.check_rounded, color: palette.link),
          RowTrailing.none => null,
        };
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: height),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          side + indent,
          YiviSpace.x12,
          YiviSpace.x12,
          YiviSpace.x12,
        ),
        child: Row(
          spacing: gap,
          children: [
            ?leading,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: palette
                        .body(
                          16,
                          weight: danger ? FontWeight.w600 : FontWeight.w400,
                        )
                        .copyWith(
                          color: danger ? palette.danger : palette.text,
                        ),
                  ),
                  if (subtitle case final subtitle?)
                    Text(
                      subtitle,
                      maxLines: subtitleMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: palette.paragraphSmall.copyWith(
                        height: 20 / 14,
                        color: palette.secondaryText,
                      ),
                    ),
                ],
              ),
            ),
            if (value case final value?)
              Text(
                value,
                style: palette.paragraphSmall.copyWith(
                  color: palette.secondaryText,
                ),
              ),
            ?end,
          ],
        ),
      ),
    );
    return Semantics(
      link: link,
      enabled: enabled,
      selected: selected,
      child: Material(
        color: selected ? palette.tint : Colors.transparent,
        child: IgnorePointer(
          ignoring: !enabled,
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: InkWell(onTap: onTap, child: row),
          ),
        ),
      ),
    );
  }
}
